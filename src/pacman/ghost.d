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
    
    static real distance(vec2i a, vec2i b)
    {
        return sqrt(cast(real)(a.x - b.x) ^^ 2 + cast(real)(a.y - b.y) ^^ 2);
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
        if(goal != player.gridPosition)
        {
            goal = player.gridPosition;
            
            find_path;
        }
        
        if(path.length == 0)
            return Direction.NONE;
        
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

final class Ghost: Creature
{
    static int textureRefcount = 0;
    static SDL2Texture bodyTexture;
    static SDL2Texture eyesTexture;
    static SDL2Texture eyesBackgroundTexture;
    vec3i color;
    vec2i eyesOffset;
    BaseAI ai;
    
    this(vec3i color)
    {
        if(bodyTexture is null)
        {
            bodyTexture = load_texture("res/ghost_body.png");
            eyesTexture = load_texture("res/ghost_eyes.png");
            eyesBackgroundTexture = load_texture("res/ghost_eyes_background.png");
        }
        
        textureRefcount++;
        speed = TILE_SIZE * 2.5;
        ignoreWalls = false;
        this.color = color;
        ai = new PathingAI(this);
    }
    
    ~this()
    {
        textureRefcount--;
        
        if(textureRefcount <= 0)
        {
            bodyTexture.close;
            eyesTexture.close;
            eyesBackgroundTexture.close;
        }
    }
    
    override void update()
    {
        super.update;
        
        if(!moving && !startMoving)
        {
            wantedVelocity = directionOffsets[ai.next_direction];
            eyesOffset = cast(vec2i)(wantedVelocity * vec2(2, 3));
            startMoving = true;
        }
    }
    
    override void render()
    {
        immutable x = cast(int)screenPosition.x;
        immutable y = cast(int)screenPosition.y;
        
        bodyTexture.setColorMod(
            cast(ubyte)color.r,
            cast(ubyte)color.g,
            cast(ubyte)color.b,
        );
        renderer.copy(eyesBackgroundTexture, x, y);
        renderer.copy(bodyTexture, x, y);
        renderer.copy(eyesTexture, x + eyesOffset.x, y + eyesOffset.y);
    }
}
