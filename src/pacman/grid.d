module pacman.grid;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.file;
import std.json;

import gfm.sdl2;

import pacman;
import pacman.texture;
import pacman.globals;

immutable vec2i[Direction] directionOffsets;
immutable Direction[Direction] directionReversals;

static this()
{
    vec2i[Direction] offsets;
    Direction[Direction] reversals;
    offsets[Direction.NORTH] = vec2i(0, 1);
    offsets[Direction.EAST] = vec2i(1, 0);
    offsets[Direction.SOUTH] = vec2i(0, -1);
    offsets[Direction.WEST] = vec2i(-1, 0);
    offsets[Direction.NONE] = vec2i(0, 0);
    reversals[Direction.NORTH] = Direction.SOUTH;
    reversals[Direction.EAST] = Direction.WEST;
    reversals[Direction.SOUTH] = Direction.NORTH;
    reversals[Direction.WEST] = Direction.EAST;
    
    offsets.rehash;
    reversals.rehash;
    
    directionOffsets = offsets.assumeUnique;
    directionReversals = reversals.assumeUnique;
}

enum TileType
{
    NONE,
    WALL,
    FLOOR,
    TASTY_FLOOR, //floor with a dot
    VERY_TASTY_FLOOR, //floor with a thicker dot - makes ghosts scared
    PLAYER_SPAWN,
    GHOST_SPAWN,
    
    max, //special value to test validity in to_tile_type
}

enum Direction
{
    NONE,
    NORTH,
    EAST,
    SOUTH,
    WEST,
}

struct Tile
{
    TileType type;
    Direction[] adjacentWalls = null;
}

TileType to_tile_type(long value)
{
    enforce(value >= 0 && value < cast(long)TileType.max, "Invalid tile type: " ~ value.to!string);
    
    return cast(TileType)value;
}

final class Grid
{
    TextureData[TileType] textures;
    TextureData[Direction] wallTextures;
    vec2i size;
    vec2i playerSpawn;
    vec2i[] ghostSpawns;
    Tile[] tiles;
    
    this()
    {
        textures[TileType.WALL] = get_texture("res/wall.png");
        textures[TileType.FLOOR] = get_texture("res/floor.png");
        textures[TileType.TASTY_FLOOR] = get_texture("res/tasty_floor.png");
        textures[TileType.VERY_TASTY_FLOOR] = get_texture("res/very_tasty_floor.png");
        textures[TileType.max] = get_texture("res/missing.png");
        wallTextures[Direction.NORTH] = get_texture("res/wall_north.png");
        wallTextures[Direction.EAST] = get_texture("res/wall_east.png");
        wallTextures[Direction.SOUTH] = get_texture("res/wall_south.png");
        wallTextures[Direction.WEST] = get_texture("res/wall_west.png");
        wallTextures[Direction.NONE] = get_texture("res/wall_middle.png");
        
        textures.rehash;
        wallTextures.rehash;
    }
    
    void load(string path)
    {
        info("Loading map from ", path);
        
        auto text = path.readText;
        auto json = text.parseJSON;
        size_t index;
        JSONValue[] mapData = json["tiles"].array;
        
        reset(
            vec2i(
                cast(int)json["width"].integer,
                cast(int)json["height"].integer,
            )
        );
        infof("Map is %d by %d, tile data is of length %d (expecting %d)", size.x, size.y, mapData.length, tiles.length);
        enforce(mapData.length == tiles.length, "Map data has invalid length");
        
        JSONValue[] transposed = new JSONValue[mapData.length];
        
        foreach(row; 0 .. size.y)
        {
            immutable dataStart = size.x * (size.y - 1 - row);
            immutable dataEnd = dataStart + size.x;
            immutable tposedStart = size.x * row;
            immutable tposedEnd = tposedStart + size.x;
            transposed[tposedStart .. tposedEnd] = mapData[dataStart .. dataEnd];
        }
        
        tiles = transposed.map!(json => Tile(json.integer.to_tile_type)).array;
        
        bake;
    }
    
    void reset(vec2i newSize)
    {
        size = newSize;
        playerSpawn = playerSpawn.init;
        ghostSpawns = ghostSpawns.init;
        //reset all tile types to NONE
        tiles.length = 0;
        tiles.length = size.x * size.y;
    }
    
    void bake()
    {
        foreach(index, ref tile; tiles)
        {
            immutable position = index_to_coords(index);
            
            //fill in data from special tile types
            switch(tile.type)
            {
                case TileType.PLAYER_SPAWN:
                    playerSpawn = index_to_coords(index);
                    tile.type = TileType.FLOOR;
                    
                    break;
                case TileType.GHOST_SPAWN:
                    ghostSpawns ~= index_to_coords(index);
                    tile.type = TileType.FLOOR;
                    
                    break;
                default:
            }
            
            //calculate adjacency data for wall tiles
            Direction[] adjacentWalls;
            
            if(tile.type != TileType.WALL)
                continue;
            
            foreach(direction, offset; directionOffsets)
            {
                immutable otherPos = position + offset;
                
                if(direction == Direction.NONE)
                    continue;
                
                if(!exists(otherPos))
                    continue;
                
                if(this[otherPos].type == TileType.WALL)
                    adjacentWalls ~= direction;
            }
            
            tile.adjacentWalls = adjacentWalls;
        }
    }
    
    void render()
    {
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                void blit(TextureData texture)
                {
                    renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
                }
                
                Tile *tile = this[vec2i(x, y)];
                
                switch(tile.type) with(TileType)
                {
                    case WALL:
                        //TODO: rect filling
                        //renderer.fillRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
                        blit(wallTextures[Direction.NONE]);
                        
                        if(tile.adjacentWalls.length == 0)
                            break;
                        else
                            foreach(direction; tile.adjacentWalls)
                                blit(wallTextures[direction]);
                        
                        break;
                    case FLOOR:
                    case TASTY_FLOOR:
                    case VERY_TASTY_FLOOR:
                        blit(textures[tile.type]);
                        
                        break;
                    case NONE:
                    case PLAYER_SPAWN:
                    case GHOST_SPAWN:
                        continue;
                    default:
                        blit(textures[TileType.max]);
                }
            }
    }
    
    size_t coords_to_index(inout vec2i position)
    {
        return position.y * size.x + position.x;
    }
    
    vec2i index_to_coords(size_t index)
    {
        return vec2i(cast(int)(index % size.x), cast(int)(index / size.x));
    }
    
    bool exists(inout vec2i position)
    {
        return
            position.x >= 0 && position.x < size.x &&
            position.y >= 0 && position.y < size.y
        ;
    }
    
    bool solid(inout vec2i position)
    {
        TileType type = this[position].type;
        
        return type == TileType.WALL;
    }
    
    Tile *opIndex(inout vec2i position)
    {
        enforce(tiles.length > 0, "Accessing tiles on an uninitialized map");
        enforce(exists(position), "Attempting to access a tile that is out of bounds");
        
        return &(tiles[coords_to_index(position)]);
    }
}
