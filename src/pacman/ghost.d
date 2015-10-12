module pacman.ghost;

import std.experimental.logger;
import std.random;
import std.algorithm;
import std.math;

import gfm.sdl2;

import pacman;
import pacman.creature;
import pacman.texture;
import pacman.globals;
import pacman.grid;

mixin template AIConstructor()
{
    this(Ghost ghost)
    {
        this.ghost = ghost;
    }
}

class BaseAI
{
    Ghost ghost;
    
    abstract Direction next_direction();
}

class WanderAI: BaseAI
{
    Direction lastDirection = Direction.NONE;
    
    mixin AIConstructor;
    
    override Direction next_direction()
    {
        Direction[] availableDirections;
        
        foreach(direction, offset; directionOffsets)
            if(direction != Direction.NONE)
            {
                immutable newPosition = ghost.gridPosition + offset;
                
                if(grid.exists(newPosition) && !grid.solid(newPosition))
                    availableDirections ~= direction;
            }
        
        if(availableDirections.length == 0)
            return Direction.NONE;
        
        if(availableDirections.length > 1)
            if(lastDirection != Direction.NONE)
            {
                foreach(index, direction; availableDirections)
                {
                    if(directionReversals[direction] == lastDirection)
                    {
                        availableDirections = availableDirections.remove(index);
                        
                        break;
                    }
                }
            }
        
        Direction selectedDirection = availableDirections[uniform(0, $)];
        lastDirection = selectedDirection;
        
        return selectedDirection;
    }
}

class SimplePathingAI: BaseAI
{
    mixin AIConstructor;
    
    override Direction next_direction()
    {
        immutable start = ghost.gridPosition;
        immutable goal = player.gridPosition;
        immutable currentDistance = distance(start, goal);
        Direction result;
        
        if(currentDistance < 1)
            return Direction.NONE;
        
        foreach(direction, offset; directionOffsets)
        {
            immutable next = start + offset;
            
            if(!grid.exists(next))
                continue;
            
            immutable nextDistance = distance(next, goal);
            
            if(nextDistance < currentDistance)
            {
                result = direction;
                
                break;
            }
        }
        
        return result;
    }
}

class PathingAI: BaseAI
{
    Direction[] path;
    vec2i goal = vec2i(-1, -1);
    
    struct HashableVector
    {
        vec2i data;
        
        size_t toHash() const nothrow @safe
        {
            enum prime1 = 73856093;
            enum prime2 = 19349663;
            enum modulo = size_t.max;
            
            return ((data.x * prime1) ^ (data.y * prime2)) % modulo;
        }
    }
    
    mixin AIConstructor;
    
    override Direction next_direction()
    {
        if(goal != ghost.get_goal)
        {
            goal = ghost.get_goal;
            
            find_path;
        }
        
        if(path.length == 0)
        {
            if(ghost.gridPosition == goal)
                return Direction.NONE;
            else
                find_path;
        }
        
        Direction result = path[0];
        path = path[1 .. $];
        
        return result;
    }
    
    void find_path()
    {
        static immutable directions = [
            Direction.NORTH,
            Direction.EAST,
            Direction.SOUTH,
            Direction.WEST,
        ];
        vec2i position = ghost.gridPosition;
        path.length = 0;
        bool[HashableVector] visited = [HashableVector(position): true];
        size_t count;
        
        while(true)
        {
            if(count++ > 5000)
            {
                warning("Could not find a path: timed out");
                
                path.length = 0;
                
                break;
            }
            
            if(position == goal)
                break;
            
            real currentCost = real.max;
            Direction bestDirection = Direction.NONE;
            vec2i nextPosition = position;
            
            foreach(direction; directions)
            {
                immutable offset = directionOffsets[direction];
                immutable newPosition = position + offset;
                
                if(HashableVector(newPosition) in visited)
                    continue;
                
                if(!grid.exists(newPosition) || grid.solid(newPosition))
                    continue;
                
                immutable cost = heuristic(newPosition, goal);
                
                if(cost < currentCost)
                {
                    currentCost = cost;
                    bestDirection = direction;
                    nextPosition = newPosition;
                }
            }
            
            if(bestDirection == Direction.NONE)
                break;
            
            path ~= bestDirection;
            position = nextPosition;
            visited[HashableVector(position)] = true;
        }
    }
    
    static real heuristic(vec2i a, vec2i b)
    {
        return 10.0L * (abs(a.x - b.x) + abs(a.y - b.y));
    }
}

class RunAwayAI: BaseAI
{
    mixin AIConstructor;
    
    override Direction next_direction()
    {
        immutable start = ghost.gridPosition;
        immutable goal = player.gridPosition;
        immutable currentDistance = distance(start, goal);
        Direction result;
        
        if(currentDistance < 1)
            return Direction.NONE;
        
        foreach(direction, offset; directionOffsets)
        {
            immutable next = start + offset;
            
            if(!grid.exists(next) || grid.solid(next))
                continue;
            
            immutable nextDistance = distance(next, goal);
            
            if(nextDistance > currentDistance)
            {
                result = direction;
                
                break;
            }
        }
        
        if(result == Direction.init)
            info("scared ghost has nowhere to go! :(");
        
        return result;
    }
}

final class Ghost: Creature
{
    enum KILL_DISTANCE = 0.75;
    enum SPEED_NORMAL = TILE_SIZE * 2.5;
    enum SPEED_SCARED = TILE_SIZE * 2.0;
    static TextureData bodyTexture;
    static TextureData bodyTextureScared;
    static TextureData eyesTexture;
    static TextureData eyesBackgroundTexture;
    vec3f color;
    vec2i eyesOffset;
    vec2i spawnpoint;
    bool scared;
    bool firstUpdate = true;
    BaseAI ai;
    BaseAI lastAI;
    
    this(vec3f color)
    {
        if(bodyTexture.texture is null)
        {
            bodyTexture = get_texture("res/ghost_body.png");
            bodyTextureScared = get_texture("res/ghost_body_scared.png");
            eyesTexture = get_texture("res/ghost_eyes.png");
            eyesBackgroundTexture = get_texture("res/ghost_eyes_background.png");
        }
        
        speed = TILE_SIZE * 2.5;
        ignoreWalls = false;
        movesWhenDead = true;
        this.color = color;
        ai = new PathingAI(this);
    }
    
    override void reset()
    {
        super.reset;
        
        firstUpdate = true;
        speed = SPEED_NORMAL;
        
        if(lastAI !is null)
        {
            ai = lastAI;
            lastAI = null;
        }
    }
    
    override void update()
    {
        super.update;
        
        if(firstUpdate)
        {
            firstUpdate = false;
            spawnpoint = gridPosition;
            
            info("Ghost spawnpoint at ", spawnpoint);
        }
        
        if(!moving && !startMoving)
        {
            wantedVelocity = directionOffsets[ai.next_direction];
            eyesOffset = cast(vec2i)(wantedVelocity * vec2(2, 3));
            startMoving = true;
        }
        
        if(dead)
        {
            if(gridPosition == spawnpoint)
                set_alive;
            
            return;
        }
        
        if(distance(player.screenPosition, screenPosition) <= KILL_DISTANCE)
        {
            if(scared)
            {
                set_not_scared;
                set_dead;
                
                player.score += player.POINTS_GHOST;
            }
            else
                player.dead = true;
        }
    }
    
    override void render()
    {
        immutable x = cast(int)screenPosition.x;
        immutable y = cast(int)screenPosition.y;
        vec3f finalColor = color;
        
        if(scared)
        {
            int timeRemaining = player.EMPOWERED_TIME - player.empoweredTime;
            
            if(timeRemaining < 100 && timeRemaining % 20 <= 10)
                finalColor = vec3f(0.82, 0.82, 0.82);
            else
                finalColor = vec3f(0.08, 0.08, 1.00);
        }
        
        renderer.copy(eyesBackgroundTexture, x, y);
        if(!dead) renderer.copy(scared ? bodyTextureScared : bodyTexture, x, y, 0, finalColor);
        renderer.copy(eyesTexture, x + eyesOffset.x, y + eyesOffset.y);
    }
    
    void set_scared()
    {
        if(scared)
            return;
        
        scared = true;
        speed = SPEED_SCARED;
        lastAI = ai;
        ai = new RunAwayAI(this);
    }
    
    void set_not_scared()
    {
        if(!scared)
            return;
        
        scared = false;
        speed = SPEED_NORMAL;
        ai = lastAI;
        lastAI = null;
    }
    
    void set_dead()
    {
        if(dead)
            return;
        
        info("Ghost died");
        
        dead = true;
        lastAI = ai;
        ai = new PathingAI(this);
    }
    
    void set_alive()
    {
        if(!dead)
            return;
        
        info("Ghost revived");
        
        dead = false;
        ai = lastAI;
        lastAI = null;
    }
    
    vec2i get_goal()
    {
        if(dead)
            return spawnpoint;
        else
            return player.gridPosition;
    }
}

private real distance(VectorType)(VectorType a, VectorType b)
{
    return sqrt(cast(real)(a.x - b.x) ^^ 2 + cast(real)(a.y - b.y) ^^ 2);
}
