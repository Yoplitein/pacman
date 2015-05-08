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
    
    TextureData[NUM_TEXTURES] animationFrames;
    TextureData activeTexture;
    
    uint textureIndex;
    bool incrementTexture = true;
    real lastAnimationTime = 0;
    real rotation = 0; //in degrees
    
    this()
    {
        foreach(index; 0 .. NUM_TEXTURES)
            animationFrames[index] = get_texture("res/player%d.png".format(index));
        
        activeTexture = animationFrames[0];
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
            
            if(textureIndex == 0 || textureIndex == NUM_TEXTURES - 1)
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
            wantedVelocity.y += 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_DOWN))
        {
            wantedVelocity.y -= 1;
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
        
        //TODO: rotation
        renderer.copy(
            activeTexture,
            cast(int)screenPosition.x,
            cast(int)screenPosition.y,
            rotation
            /*src,
            dst,
            rotation,
            &rotOrigin,
            SDL_FLIP_NONE*/
        );
    }
}
