module pacman.grid;

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
    PLAYER_SPAWN,
    GHOST_SPAWN,
    
    max, //special value to test validity in to_tile_type
}

enum Direction
{
    NORTH,
    EAST,
    SOUTH,
    WEST,
    NONE,
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
        textures[TileType.max] = get_texture("res/missing.png");
        wallTextures[Direction.SOUTH] = get_texture("res/wall_north.png");
        wallTextures[Direction.EAST] = get_texture("res/wall_east.png");
        wallTextures[Direction.NORTH] = get_texture("res/wall_south.png");
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
        size.x = cast(int)json["width"].integer;
        size.y = cast(int)json["height"].integer;
        tiles.length = size.x * size.y;
        size_t index;
        JSONValue[] mapData = json["tiles"].array;
        
        infof("Map is %d by %d, tile data is of length %d (expecting %d)", size.x, size.y, mapData.length, tiles.length);
        enforce(mapData.length == tiles.length, "Map data has invalid length");
        
        vec2i coords(size_t index)
        {
            return vec2i(cast(int)(index % size.x), size.y - 1 - cast(int)(index / size.x));
        }
        
        //fill in tile data
        foreach(tileID; mapData)
            switch(tileID.integer)
            {
                case TileType.PLAYER_SPAWN:
                    playerSpawn = coords(index);
                    tileID = JSONValue(cast(int)TileType.FLOOR);
                    
                    goto default;
                case TileType.GHOST_SPAWN:
                    ghostSpawns ~= coords(index);
                    tileID = JSONValue(cast(int)TileType.FLOOR);
                    
                    goto default;
                default:
                    tiles[index++] = Tile(tileID.integer.to_tile_type);
            }
        
        //calculate adjacent walls
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                immutable pos = vec2i(x, y);
                Tile *tile = this[pos];
                Direction[] adjacentWalls;
                
                if(tile.type != TileType.WALL)
                    continue;
                
                foreach(direction, offset; directionOffsets)
                {
                    immutable otherPos = pos + offset;
                    
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
        return (size.y - 1 - position.y) * size.y + position.x;
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
