module pacman.player;

import std.experimental.logger;
import std.math;
import std.string;

import gfm.sdl2;
import gfm.math: degrees;

import pacman;
import pacman.texture;
import pacman.globals;

class Player
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 0.015;
    enum PIXELS_PER_SECOND = TILE_SIZE * 3.5;
    
    vec2 position = vec2(0, 0);
    vec2 velocity = vec2(0, 0);
    SDL2Texture[] animationFrames;
    SDL2Texture activeTexture;
    uint textureIndex;
    bool animate = true;
    bool increment = true;
    real lastAnimationTime = 0;
    real rotation = 0;
    
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
        update_velocity;
        
        position += timeDelta * velocity * PIXELS_PER_SECOND;
        
        if(animate && timeSeconds - lastAnimationTime > ANIMATION_DELAY)
        {
            if(increment)
                textureIndex++;
            else
                textureIndex--;
            
            if(textureIndex == 0 || textureIndex == animationFrames.length - 1)
                increment = !increment;
            
            activeTexture = animationFrames[textureIndex];
            lastAnimationTime = timeSeconds;
        }
    }
    
    void update_velocity()
    {
        velocity = vec2(0, 0);
        bool update;
        
        if(sdl.keyboard.isPressed(SDLK_LEFT))
        {
            velocity.x -= 1;
            update = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_RIGHT))
        {
            velocity.x += 1;
            update = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_UP))
        {
            velocity.y -= 1;
            update = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_DOWN))
        {
            velocity.y += 1;
            update = true;
        }
        
        if(update)
            rotation = 180 + atan2(velocity.y, velocity.x).degrees;
        
        animate = update; //only animate when moving
    }
    
    void render()
    {
        const width = activeTexture.width;
        const height = activeTexture.height;
        auto src = SDL_Rect(0, 0, width, height);
        auto dst = SDL_Rect(cast(int)position.x, cast(int)position.y, width, height);
        auto rotOrigin = SDL_Point(cast(int)(width * 0.5L), cast(int)(height * 0.5L));
        
        renderer.copyEx(
            activeTexture,
            src,
            dst,
            rotation,
            &rotOrigin,
            SDL_FLIP_NONE
        );
    }
}
