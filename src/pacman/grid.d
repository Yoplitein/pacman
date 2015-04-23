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

enum TileType
{
    NONE,
    WALL,
    FLOOR,
    TASTY_FLOOR, //floor with a dot
    PLAYER_SPAWN,
    
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
    vec2i[Direction] directionOffsets;
    SDL2Texture[TileType] textures;
    SDL2Texture[Direction] wallTextures;
    vec2i size;
    vec2i playerSpawn;
    Tile[] tiles;
    
    this()
    {
        immutable north = vec2i(0, -1);
        immutable east = vec2i(1, 0);
        immutable south = vec2i(0, 1);
        immutable west = vec2i(-1, 0);
        directionOffsets[Direction.NORTH] = north;
        directionOffsets[Direction.EAST] = east;
        directionOffsets[Direction.SOUTH] = south;
        directionOffsets[Direction.WEST] = west;
        textures[TileType.WALL] = load_texture("res/wall.png");
        textures[TileType.FLOOR] = load_texture("res/floor.png");
        textures[TileType.TASTY_FLOOR] = load_texture("res/tasty_floor.png");
        textures[TileType.max] = load_texture("res/missing.png");
        wallTextures[Direction.NORTH] = load_texture("res/wall_north.png");
        wallTextures[Direction.EAST] = load_texture("res/wall_east.png");
        wallTextures[Direction.SOUTH] = load_texture("res/wall_south.png");
        wallTextures[Direction.WEST] = load_texture("res/wall_west.png");
        wallTextures[Direction.NONE] = load_texture("res/wall_middle.png");
        
        directionOffsets.rehash;
        textures.rehash;
        wallTextures.rehash;
    }
    
    ~this()
    {
        foreach(texture; textures.values ~ wallTextures.values)
            texture.close;
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
        
        foreach(tileID; mapData)
            switch(tileID.integer)
            {
                case TileType.PLAYER_SPAWN:
                    size_t x = index % size.x;
                    size_t y = index / size.x;
                    playerSpawn = vec2i(cast(int)x, cast(int)y);
                    tileID = JSONValue(cast(int)TileType.FLOOR);
                    
                    goto default;
                default:
                    tiles[index++] = Tile(tileID.integer.to_tile_type);
            }
        
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
                void blit(SDL2Texture texture)
                {
                    renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
                }
                
                Tile *tile = this[vec2i(x, y)];
                
                switch(tile.type) with(TileType)
                {
                    case WALL:
                        renderer.fillRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
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
                        continue;
                    default:
                        blit(textures[TileType.max]);
                }
            }
    }
    
    size_t coords_to_index(inout vec2i position)
    {
        return position.y * size.y + position.x;
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
