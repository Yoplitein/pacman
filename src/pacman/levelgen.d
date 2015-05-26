module pacman.levelgen;

import core.thread;
import std.algorithm;
import std.experimental.logger;
import std.random;
import std.range;

import pacman.globals;
import pacman.grid;
import pacman;

private struct Update
{
    vec2i position;
    TileType newType = TileType.NONE;
}

void generate_level()
{
    static immutable sizeChoices = iota(11 * 1, 11 * 2, 2);
    /*immutable size = vec2i(
        //sizeChoices[uniform(0, $)],
        //sizeChoices[uniform(0, $)],
        uniform!"[]"(11, 32),
        uniform!"[]"(11, 18),
    );*/
    immutable size = vec2i(39, 18);
    
    info("Generating new level of size ", size);
    grid.reset(size);
    
    grid.playerSpawn = vec2i(size.x / 2, size.y / 2);
    
    shape;
    simulate;
    grid.bake;
    info("\aLevel generated");
}

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
            
            if(x % 5 == 0)
                yield;
        }
}

private void simulate()
{
    size_t simulations = uniform(5, 25);
    
    foreach(generation; 0 .. simulations)
    {
        Update[] updates;
        
        info("Generation ", generation);
        
        foreach(y; 0 .. grid.size.y)
            foreach(x; 0 .. grid.size.x)
            {
                immutable position = vec2i(x, y);
                Update update = Update(position);
                
                if(x == 0)
                    yield;
                
                if(position.on_edge)
                    continue;
                
                if(position.needs_update(update))
                {
                    grid[position].type = update.newType;
                }
            }
        
        /*foreach(index, update; updates)
        {
            grid[update.position].type = update.newType;
            
            if(index % 10 == 0)
                yield;
        }*/
    }
}

private bool needs_update(vec2i position, ref Update update)
{
    immutable type = grid[position].type;
    //with moore neighborhoods
    immutable rules = [
        TileType.TASTY_FLOOR: [
            TileType.TASTY_FLOOR: [
                0: TileType.WALL,
                1: TileType.WALL,
                2: TileType.TASTY_FLOOR,
                3: TileType.TASTY_FLOOR,
                4: TileType.TASTY_FLOOR,
                5: TileType.WALL,
                6: TileType.WALL,
                7: TileType.WALL,
                8: TileType.WALL,
            ],
            TileType.WALL: [
                3: TileType.WALL,
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
    //with neumann neighborhoods
    /*immutable rules = [
        TileType.TASTY_FLOOR: [
            0: TileType.WALL,
            1: TileType.WALL,
            2: TileType.TASTY_FLOOR,
            3: TileType.TASTY_FLOOR,
            4: TileType.TASTY_FLOOR,
        ],
        TileType.WALL: [
            0: TileType.WALL,
            1: TileType.WALL,
            2: TileType.WALL,
            3: TileType.TASTY_FLOOR,
            4: TileType.TASTY_FLOOR,
        ],
    ];*/
    
    /*
        Any wall cell with fewer than two wall neighbours becomes floor
        Any wall cell with two or three wall neighbours lives
        Any wall cell with more than three wall neighbours becomes floor
        Any floor cell with exactly three wall neighbours becomes a wall cell
    */
    
    switch(type)
    {
        case TileType.WALL:
        case TileType.TASTY_FLOOR:
            size_t adjacent = position.count_adjacent(type);
            TileType newType = rules[type][type].get(cast(int)adjacent, type);
            
            if(newType != type)
            {
                update.newType = newType;
                
                return true;
            }
            
            TileType inverseType = type.inverse;
            adjacent = position.count_adjacent(inverseType);
            newType = rules[type][inverseType].get(cast(int)adjacent, type);
            
            if(newType != type)
            {
                update.newType = newType;
                
                return true;
            }
            
            break;
        default:
    }
    
    return false;
}

/*private bool can_find_adjacent(vec2i position, TileType targetType, Direction ignoredDirection)
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
}*/

private size_t count_adjacent(vec2i position, TileType targetType)
{
    immutable mooreOffsets = [
        directionOffsets[Direction.NORTH],
        directionOffsets[Direction.EAST],
        directionOffsets[Direction.SOUTH],
        directionOffsets[Direction.WEST],
        directionOffsets[Direction.NORTH] + directionOffsets[Direction.EAST],
        directionOffsets[Direction.NORTH] + directionOffsets[Direction.WEST],
        directionOffsets[Direction.SOUTH] + directionOffsets[Direction.EAST],
        directionOffsets[Direction.SOUTH] + directionOffsets[Direction.WEST],
    ];
    size_t count;
    
    foreach(offset; mooreOffsets)
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
