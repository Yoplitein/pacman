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

TileType to_tile_type(long value)
{
    enforce(value >= 0 && value < cast(long)TileType.max, "Invalid tile type: " ~ value.to!string);
    
    return cast(TileType)value;
}

final class Grid
{
    SDL2Texture[TileType] textures;
    vec2i size;
    vec2i playerSpawn;
    TileType[] tiles;
    
    this()
    {
        textures[TileType.WALL] = load_texture("res/wall.png");
        textures[TileType.FLOOR] = load_texture("res/floor.png");
        textures[TileType.TASTY_FLOOR] = load_texture("res/tasty_floor.png");
        
        textures.rehash;
    }
    
    ~this()
    {
        foreach(texture; textures.values)
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
                    int x = index % size.x;
                    int y = index / size.x;
                    playerSpawn = vec2i(x, y);
                    tileID = JSONValue(cast(int)TileType.FLOOR);
                    
                    goto default;
                default:
                    tiles[index++] = tileID.integer.to_tile_type;
            }
    }
    
    void render()
    {
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                TileType type = this[vec2i(x, y)];
                SDL2Texture texture;
                
                switch(this[vec2i(x, y)]) with(TileType)
                {
                    case WALL:
                    case FLOOR:
                    case TASTY_FLOOR:
                        texture = textures[type];
                        
                        break;
                    default:
                        continue;
                }
                
                renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
            }
    }
    
    bool solid(inout vec2i tilePos)
    {
        TileType type = this[tilePos];
        
        return type == TileType.WALL;
    }
    
    ref TileType opIndex(inout vec2i tilePos)
    {
        size_t index = tilePos.y * size.y + tilePos.x;
        
        enforce(tiles.length > 0, "Accessing tiles on an uninitialized map");
        enforce(index >= 0 && index <= tiles.length, "Attempting to access a tile that is out of bounds");
        
        return tiles[index];
    }
}
