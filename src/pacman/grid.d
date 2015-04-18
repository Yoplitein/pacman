module pacman.grid;

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
    PLAYER_SPAWN,
}

final class Grid
{
    SDL2Texture texture;
    vec2i size;
    vec2i playerSpawn;
    TileType[] tiles;
    
    this()
    {
        texture = load_texture("res/debug.png");
        
    }
    
    ~this()
    {
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
            tiles[index++] = cast(TileType)tileID.integer;
    }
    
    void render()
    {
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                if(!solid(vec2i(x, y)))
                    continue;
                
                renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
            }
    }
    
    bool solid(inout vec2i tilePos)
    {
        TileType type = this[tilePos];
        
        return type != TileType.NONE;
    }
    
    ref TileType opIndex(inout vec2i tilePos)
    {
        size_t index = tilePos.y * size.y + tilePos.x;
        
        enforce(tiles.length > 0, "Accessing tiles on an uninitialized map");
        enforce(index >= 0 && index <= tiles.length, "Attempting to access a tile that is out of bounds");
        
        return tiles[index];
    }
}
