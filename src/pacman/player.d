module pacman.player;

import std.string;

import gfm.sdl2;

import pacman.texture;
import pacman.globals;

class Player
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 15;
    SDL2Texture[] animationFrames;
    SDL2Texture activeTexture;
    uint textureIndex;
    bool animate = true;
    bool increment = true;
    uint lastAnimationStep;
    
    this()
    {
        foreach(index; 0 .. NUM_TEXTURES)
            animationFrames ~= load_texture("res/player%d.png".format(index));
        
        activeTexture = animationFrames[0];
    }
    
    ~this()
    {
        foreach(texture; animationFrames)
            texture.close;
    }
    
    void update()
    {
        uint now = SDL_GetTicks();
        
        if(!animate)
            return;
        
        if(now - lastAnimationStep > ANIMATION_DELAY)
        {
            if(increment)
                textureIndex++;
            else
                textureIndex--;
            
            if(textureIndex == 0 || textureIndex == animationFrames.length - 1)
                increment = !increment;
            
            activeTexture = animationFrames[textureIndex];
            lastAnimationStep = now;
        }
    }
    
    void render()
    {
        renderer.copy(activeTexture, 100, 100);
    }
}
