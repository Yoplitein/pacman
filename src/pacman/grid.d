module pacman.grid;

import gfm.sdl2;

import pacman.texture;
import pacman.globals;

class Grid
{
    SDL2Texture texture;
    
    this()
    {
        texture = load_texture("res/debug.png");
    }
    
    ~this()
    {
        texture.close;
    }
    
    void render()
    {
        immutable tilesX = WIDTH / TILE_SIZE;
        immutable tilesY = HEIGHT / TILE_SIZE;
        
        foreach(y; 0 .. tilesY - 1)
            foreach(x; 0 .. tilesX - 1)
            {
                if(y != 0 && y != tilesY - 2)
                    if(x != 0 && x != tilesX - 2)
                        continue;
                
                renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
            }
    }
}
