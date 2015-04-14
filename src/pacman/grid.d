module pacman.grid;

import gfm.sdl2;

import pacman;
import pacman.texture;
import pacman.globals;

enum TileType
{
    NONE,
    WALL,
}

final class Grid
{
    SDL2Texture texture;
    int width;
    int height;
    TileType[] tiles;
    
    this()
    {
        texture = load_texture("res/debug.png");
        width = 8;
        height = 8;
        tiles.length = width * height;
    }
    
    ~this()
    {
        texture.close;
    }
    
    void render()
    {
        foreach(y; 0 .. width)
            foreach(x; 0 .. height)
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
        size_t index = tilePos.y * height + tilePos.x;
        
        assert(index >= 0 && index <= tiles.length);
        
        return tiles[index];
    }
}
