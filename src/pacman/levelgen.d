module pacman.levelgen;

import core.thread;
import std.algorithm;
import std.experimental.logger;
import std.random;
import std.range;

import pacman.globals;
import pacman.grid;
import pacman;

void generate_level()
{
    static immutable sizeChoices = iota(11 * 1, 11 * 2, 2);
    immutable size = vec2i(
        sizeChoices[uniform(0, $)],
        sizeChoices[uniform(0, $)],
    );
    
    grid.reset(size);
    
    grid.playerSpawn = vec2i(size.x / 2, size.y / 2);
    
    walk;
    grid.bake;
}

private void walk()
{
    foreach(x; 0 .. grid.size.x)
    {
        if(x == 0 || x == grid.size.x - 1)
            foreach(y; 0 .. grid.size.y)
                grid[vec2i(x, y)].type = TileType.WALL;
        else
        {
            grid[vec2i(x, 0)].type = TileType.WALL;
            grid[vec2i(x, grid.size.y - 1)].type = TileType.WALL;
        }
    }
    
    Direction[] validDirections = [
        Direction.NORTH,
        Direction.EAST,
        Direction.SOUTH,
        Direction.WEST,
    ];
    vec2i position = vec2i(
        uniform(1, grid.size.x - 1),
        uniform(1, grid.size.y - 1),
    );
    vec2i[] visited;
    size_t failTimes;
    
    foreach(count; 0 .. 1000)
    {
        bool moved;
        grid[position].type = TileType.TASTY_FLOOR;
        visited ~= position;
        
        validDirections.randomShuffle;
        
        foreach(direction; validDirections)
        {
            if(direction == Direction.NONE)
                continue;
            
            immutable offset = directionOffsets[direction];
            immutable offsetPosition = position + offset;
            
            if(!grid.exists(offsetPosition))
                continue;
            
            if(grid[offsetPosition].type == TileType.WALL)
                continue;
            
            if(visited.canFind(offsetPosition))
                continue;
            
            if(failTimes < 3)
                if(offsetPosition.can_find_adjacent(TileType.TASTY_FLOOR, directionReversals[direction]))
                    continue;
            
            position += offset;
            moved = true;
            failTimes = 0;
            
            break;
        }
        
        if(!moved)
        {
            if(failTimes++ >= 10)
                break;
            
            warningf("failed to move %d times", failTimes);
        }
        
        yield;
    }
    
    foreach(y; 0 .. grid.size.y)
        foreach(x; 0 .. grid.size.x)
        {
            position = vec2i(x, y);
            
            if(grid[position].type == TileType.NONE)
                grid[position].type = TileType.WALL;
            
            yield;
        }
}

private bool can_find_adjacent(vec2i position, TileType targetType, Direction ignoredDirection)
{
    foreach(direction, offset; directionOffsets)
    {
        if(direction == Direction.NONE)
            continue;
        
        if(direction == ignoredDirection)
            continue;
        
        immutable newPosition = position + offset;
        
        if(!grid.exists(newPosition))
            continue;
        
        immutable adjacentType = grid[newPosition].type;
        
        if(adjacentType == targetType)
            return true;
    }
    
    return false;
}

private void yield()
{
    if(Fiber.getThis !is null)
    {
        grid.bake;
        Fiber.yield;
    }
}

private bool random_bool(real chance = 0.5L)
{
    return uniform!"[]"(0.0L, 1.0L) < chance;
}
