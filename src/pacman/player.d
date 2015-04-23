module pacman.player;

import std.experimental.logger;
import std.math;
import std.string;

import gfm.sdl2;
import gfm.math: degrees;

import pacman;
import pacman.creature;
import pacman.texture;
import pacman.globals;
import pacman.grid;

final class Player: Creature
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 0.015;
    
    SDL2Texture[] animationFrames;
    SDL2Texture activeTexture;
    
    uint textureIndex;
    bool incrementTexture = true;
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
    
    override void update()
    {
        super.update;
        
        if(moving && timeSeconds - lastAnimationTime > ANIMATION_DELAY)
        {
            if(incrementTexture)
                textureIndex++;
            else
                textureIndex--;
            
            if(textureIndex == 0 || textureIndex == animationFrames.length - 1)
                incrementTexture = !incrementTexture;
            
            activeTexture = animationFrames[textureIndex];
            lastAnimationTime = timeSeconds;
        }
    }
    
    override void update_velocity()
    {
        wantedVelocity = vec2i(0, 0);
        bool any;
        
        if(sdl.keyboard.isPressed(SDLK_LEFT))
        {
            wantedVelocity.x -= 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_RIGHT))
        {
            wantedVelocity.x += 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_UP))
        {
            wantedVelocity.y -= 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_DOWN))
        {
            wantedVelocity.y += 1;
            any = true;
        }
        
        startMoving = any;
    }
    
    override void begin_moving()
    {
        rotation = 180 + atan2(cast(real)wantedVelocity.y, cast(real)wantedVelocity.x).degrees;
    }
    
    override void done_moving()
    {
        Tile *currentTile = grid[gridPosition];
        
        if(currentTile.type == TileType.TASTY_FLOOR)
            currentTile.type = TileType.FLOOR;
    }
    
    override void render()
    {
        const width = activeTexture.width;
        const height = activeTexture.height;
        auto src = SDL_Rect(0, 0, width, height);
        auto dst = SDL_Rect(cast(int)screenPosition.x, cast(int)screenPosition.y, width, height);
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
