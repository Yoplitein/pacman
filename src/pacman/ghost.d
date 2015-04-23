module pacman.ghost;

import gfm.sdl2;

import pacman;
import pacman.texture;
import pacman.globals;

class Ghost
{
    SDL2Texture bodyTexture;
    SDL2Texture eyesTexture;
    SDL2Texture eyesBackgroundTexture;
    vec2i gridPosition = vec2i(-1, -1);
    
    this()
    {
        bodyTexture = load_texture("res/ghost_body.png");
        eyesTexture = load_texture("res/ghost_eyes.png");
        eyesBackgroundTexture = load_texture("res/ghost_eyes_background.png");
        
        bodyTexture.setColorMod(255, 0, 255);
    }
    
    ~this()
    {
        bodyTexture.close;
        eyesTexture.close;
        eyesBackgroundTexture.close;
    }
    
    void update()
    {
        if(gridPosition.x == -1)
            gridPosition = grid.playerSpawn;
    }
    
    void render()
    {
        immutable vec2i screenPos = gridPosition * TILE_SIZE;
        
        renderer.copy(eyesBackgroundTexture, screenPos.x, screenPos.y);
        renderer.copy(bodyTexture, screenPos.x, screenPos.y);
        renderer.copy(eyesTexture, screenPos.x, screenPos.y);
    }
}
