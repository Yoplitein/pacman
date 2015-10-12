module pacman.levelgen;

import core.thread;
import std.algorithm;
import std.experimental.logger;
import std.random;
import std.range;

import pacman.entity.grid;
import pacman.globals;
import pacman;

//offsets for Neumann neighborhoods
private immutable vec2i[] neumannOffsets;

//offsets for Moore neighborhoods
private immutable vec2i[] mooreOffsets;

static this()
{
    vec2i[] neumann = [
        directionOffsets[Direction.NORTH],
        directionOffsets[Direction.EAST],
        directionOffsets[Direction.SOUTH],
        directionOffsets[Direction.WEST],
    ];
    vec2i[] moore = neumann ~ [
        directionOffsets[Direction.NORTH] + directionOffsets[Direction.EAST],
        directionOffsets[Direction.NORTH] + directionOffsets[Direction.WEST],
        directionOffsets[Direction.SOUTH] + directionOffsets[Direction.EAST],
        directionOffsets[Direction.SOUTH] + directionOffsets[Direction.WEST],
    ];
    
    neumannOffsets = neumann.idup;
    mooreOffsets = moore.idup;
}

private struct Update
{
    vec2i position;
    TileType newType = TileType.NONE;
}

void generate_level()
{
    static immutable sizeChoices = iota(11 * 1, 11 * 2, 2);
    immutable size = vec2i(
        sizeChoices[uniform(0, $)],
        sizeChoices[uniform(0, $)],
    );
    
    info("Generating new level of size ", size);
    grid.reset(size);
    
    grid.playerSpawn = vec2i(size.x / 2, size.y / 2);
    
    info("Shaping");
    shape;
    info("Simulating");
    simulate;
    info("Shortening");
    shorten;
    info("Punching");
    punch;
    info("Placing spawns");
    place_spawns;
    info("Enhancing taste of some floors");
    place_very_tasty_floors;
    grid.bake;
    info("Level generated");
}

//set the starting shape for the level
private void shape()
{
    foreach(y; 0 .. grid.size.y)
        foreach(x; 0 .. grid.size.x)
        {
            immutable position = vec2i(x, y);
            
            if(position.on_edge)
            {
                grid[position].type = TileType.WALL;
                
                continue;
            }
            
            if(random_bool)
                grid[position].type = TileType.WALL;
            else
                grid[position].type = TileType.TASTY_FLOOR;
        }
}

//simulate the level as an automata, to smooth it out
private void simulate()
{
    immutable simulations = uniform!"[]"(50, 100);
    
    foreach(generation; 0 .. simulations)
    {
        bool updated;
        
        info("Generation ", generation);
        
        foreach(y; 0 .. grid.size.y)
            foreach(x; 0 .. grid.size.x)
            {
                immutable position = vec2i(x, y);
                Update update = Update(position);
                
                if(position.on_edge)
                    continue;
                
                if(position.needs_update(update))
                {
                    grid[update.position].type = update.newType;
                    updated = true;
                }
            }
        
        if(updated)
        {
            info("Simulation ended early");
            
            return;
        }
    }
    
    info("Simulation ended normally");
}

//shorten really long walls
private void shorten()
{
    enum percentage = 45 / 100f;
    enum minWalls = 2;
    immutable maxWallsXUpper = cast(uint)(grid.size.x * percentage);
    immutable maxWallsYUpper = cast(uint)(grid.size.y * percentage);
    
    static void loop_body(immutable vec2i position, immutable uint maxWalls, ref uint wallCount)
    {
        if(position.on_edge)
            return;
        
        if(grid[position].type == TileType.WALL)
            wallCount++;
        else
            wallCount = 0;
        
        if(wallCount > maxWalls)
        {
            grid[position].type = TileType.TASTY_FLOOR;
            wallCount = 0;
        }
    }
    
    //shorten walls on the x axis
    foreach(y; 0 .. grid.size.y)
    {
        uint wallCount;
        uint maxWalls;
        
        foreach(x; 0 .. grid.size.x)
        {
            if(wallCount == 0)
                maxWalls = uniform!"[]"(minWalls, maxWallsXUpper);
            
            loop_body(vec2i(x, y), maxWalls, wallCount);
        }
    }
    
    //shorten walls on the y axis
    foreach(x; 0 .. grid.size.x)
    {
        uint wallCount;
        uint maxWalls;
        
        foreach(y; 0 .. grid.size.y)
        {
            if(wallCount == 0)
                maxWalls = uniform!"[]"(minWalls, maxWallsYUpper);
            
            loop_body(vec2i(x, y), maxWalls, wallCount);
        }
    }
}

//punch out walls that make dead ends/make floors entirely inaccessible
private void punch()
{
    foreach(y; 0 .. grid.size.y)
    {
        foreach(x; 0 .. grid.size.x)
        {
            immutable position = vec2i(x, y);
            
            if(position.on_edge)
                continue;
            
            if(grid[position].type != TileType.TASTY_FLOOR)
                continue;
            
            if(position.count_adjacent(TileType.TASTY_FLOOR, false) >= 2)
                continue;
            
            immutable nearestWallOffset = position.find_adjacent(TileType.TASTY_FLOOR);
            
            //no neighbors, try to punch our way through to some other floors
            if(nearestWallOffset == vec2i(0, 0))
            {
                uint punchCount;
                
                warningf("Floor at %s has no neighbors!", position);
                
                foreach(offset; neumannOffsets)
                {
                    if(punchCount == 2)
                        break;
                    
                    immutable potentialFloorPosition = position + 2 * offset;
                    
                    if(!grid.exists(potentialFloorPosition) || potentialFloorPosition.on_edge)
                        continue;
                    
                    if(grid[potentialFloorPosition].type != TileType.TASTY_FLOOR)
                        continue;
                    
                    grid[position + offset].type = TileType.TASTY_FLOOR;
                    punchCount++;
                }
                
                if(punchCount == 0)
                {
                    warningf("Changed to a wall");
                    
                    grid[position].type = TileType.WALL;
                }
                
                continue;
            }
            
            //first try to continue the line of floors
            immutable idealOffset = -1 * nearestWallOffset;
            immutable idealPosition = position + idealOffset;
            
            if(grid.exists(idealPosition) && !idealPosition.on_edge)
                if(idealPosition.count_adjacent(TileType.TASTY_FLOOR, false) >= 2)
                {
                    grid[idealPosition].type = TileType.TASTY_FLOOR;
                    
                    continue;
                }
            
            //try another direction otherwise
            bool success;
            
            foreach(offset; neumannOffsets)
            {
                if(offset == nearestWallOffset || offset == idealOffset)
                    continue;
                
                immutable newPosition = position + offset;
                
                if(!grid.exists(newPosition) || newPosition.on_edge)
                    continue;
                
                if(newPosition.count_adjacent(TileType.TASTY_FLOOR, false) >= 2)
                {
                    grid[newPosition].type = TileType.TASTY_FLOOR;
                    success = true;
                    
                    break;
                }
            }
            
            if(!success)
                warning("Dead end!");
        }
    }
}

private void place_spawns()
{
    vec2i playerSpawn = nearest_floor(vec2i(grid.size.x / 2, grid.size.y / 2));
    vec2i ghostSpawn1 = nearest_floor(vec2i(0, 0));
    vec2i ghostSpawn2 = nearest_floor(vec2i(0, grid.size.y));
    vec2i ghostSpawn3 = nearest_floor(vec2i(grid.size.x, 0));
    vec2i ghostSpawn4 = nearest_floor(vec2i(grid.size.x, grid.size.y));
    
    grid[playerSpawn].type = TileType.PLAYER_SPAWN;
    grid[ghostSpawn1].type = TileType.GHOST_SPAWN;
    grid[ghostSpawn2].type = TileType.GHOST_SPAWN;
    grid[ghostSpawn3].type = TileType.GHOST_SPAWN;
    grid[ghostSpawn4].type = TileType.GHOST_SPAWN;
}

private void place_very_tasty_floors()
{
    int halfX = grid.size.x / 2;
    int halfY = grid.size.y / 2;
    vec2i pos1 = nearest_floor(vec2i(halfX, 0));
    vec2i pos2 = nearest_floor(vec2i(0, halfY));
    vec2i pos3 = nearest_floor(vec2i(grid.size.x, halfY));
    vec2i pos4 = nearest_floor(vec2i(halfX, grid.size.y));
    
    grid[pos1].type = TileType.VERY_TASTY_FLOOR;
    grid[pos2].type = TileType.VERY_TASTY_FLOOR;
    grid[pos3].type = TileType.VERY_TASTY_FLOOR;
    grid[pos4].type = TileType.VERY_TASTY_FLOOR;
}

private vec2i nearest_floor(vec2i position)
{
    static bool valid(vec2i position)
    {
        return
            grid.exists(position) &&
            !position.on_edge &&
            grid[position].type == TileType.TASTY_FLOOR
        ;
    }
    
    if(valid(position))
        return position;
    
    foreach(max; 1 .. 10)
    {
        foreach(dx; -max .. max)
            foreach(dy; -max .. max)
            {
                immutable newPosition = position + vec2i(dx, dy);
                
                if(valid(newPosition))
                    return newPosition;
            }
    }
    
    fatal("Couldn't find a floor close to ", position);
    assert(false);
}

private bool needs_update(vec2i position, ref Update update)
{
    //rules for the smoothing automata
    immutable rules = [
        //current tile's type
        TileType.TASTY_FLOOR: [
            //only look for this type when counting adjacent tiles (using Moore neighborhoods)
            TileType.TASTY_FLOOR: [
                //the new type to morph into if there are this many adjacent tiles
                0: TileType.WALL, //a floor with 0-1 or 5-8 adjacent floors will morph into a wall
                1: TileType.WALL,
                2: TileType.TASTY_FLOOR, //a floor with 2-4 adjacent floors will remain a floor
                3: TileType.TASTY_FLOOR,
                4: TileType.TASTY_FLOOR,
                5: TileType.WALL,
                6: TileType.WALL,
                7: TileType.WALL,
                8: TileType.WALL,
            ],
            TileType.WALL: [
                3: TileType.WALL, //a floor with exactly 3 adjacent walls will morph into a wall
            ],
        ],
        TileType.WALL: [
            TileType.WALL: [
                0: TileType.WALL,
                1: TileType.WALL,
                2: TileType.WALL,
                3: TileType.WALL,
                4: TileType.TASTY_FLOOR,
                5: TileType.TASTY_FLOOR,
                6: TileType.TASTY_FLOOR,
                7: TileType.TASTY_FLOOR,
                8: TileType.TASTY_FLOOR,
            ],
            TileType.TASTY_FLOOR: [
                3: TileType.TASTY_FLOOR,
            ],
        ],
    ];
    immutable currentType = grid[position].type;
    
    switch(currentType)
    {
        case TileType.WALL:
        case TileType.TASTY_FLOOR:
            //check rules for the current type
            uint adjacent = position.count_adjacent(currentType);
            TileType newType = rules[currentType][currentType].get(cast(int)adjacent, currentType);
            
            if(newType != currentType)
            {
                update.newType = newType;
                
                return true;
            }
            
            //if the above failed, then check the rules for the inverse type
            TileType inverseType = currentType.inverse;
            adjacent = position.count_adjacent(inverseType);
            newType = rules[currentType][inverseType].get(cast(int)adjacent, currentType);
            
            if(newType != currentType)
            {
                update.newType = newType;
                
                return true;
            }
            
            break;
        default:
    }
    
    return false;
}

private uint count_adjacent(vec2i position, TileType targetType, bool mooreNeighborhood = true)
{
    uint count;
    
    foreach(offset; mooreNeighborhood ? mooreOffsets : neumannOffsets)
    {
        immutable newPosition = position + offset;
        
        if(!grid.exists(newPosition))
            continue;
        
        immutable adjacentType = grid[newPosition].type;
        
        if(adjacentType == targetType)
            count++;
    }
    
    return count;
}

private vec2i find_adjacent(vec2i position, TileType targetType)
{
    foreach(offset; neumannOffsets)
    {
        immutable newPosition = position + offset;
        
        if(!grid.exists(newPosition))
            continue;
        
        if(grid[newPosition].type == targetType)
            return offset;
    }
    
    return vec2i(0, 0);
}

private bool on_edge(vec2i position)
{
    return
        position.x == 0 ||
        position.y == 0 ||
        position.x == grid.size.x - 1 ||
        position.y == grid.size.y - 1
    ;
}

private TileType inverse(TileType type)
{
    switch(type)
    {
        case TileType.WALL:
            return TileType.TASTY_FLOOR;
        case TileType.TASTY_FLOOR:
            return TileType.WALL;
        default:
            assert(false);
    }
}

private bool random_bool(real chance = 0.5L)
{
    return uniform!"[]"(0.0L, 1.0L) < chance;
}
