module pacman.ghost;

import std.random;

import gfm.sdl2;

import pacman;
import pacman.creature;
import pacman.texture;
import pacman.globals;
import pacman.grid;

final class Ghost: Creature
{
    static int textureRefcount = 0;
    static SDL2Texture bodyTexture;
    static SDL2Texture eyesTexture;
    static SDL2Texture eyesBackgroundTexture;
    vec3i color;
    vec2i eyesOffset;
    
    this(vec3i color)
    {
        if(bodyTexture is null)
        {
            bodyTexture = load_texture("res/ghost_body.png");
            eyesTexture = load_texture("res/ghost_eyes.png");
            eyesBackgroundTexture = load_texture("res/ghost_eyes_background.png");
        }
        
        textureRefcount++;
        speed = TILE_SIZE * 4.0;
        this.color = color;
    }
    
    ~this()
    {
        textureRefcount--;
        
        if(textureRefcount <= 0)
        {
            bodyTexture.close;
            eyesTexture.close;
            eyesBackgroundTexture.close;
        }
    }
    
    override void update()
    {
        super.update;
        
        if(!moving && !startMoving)
        {
            Direction[] availableDirections;
            
            foreach(direction, offset; grid.directionOffsets)
                if(grid.exists(gridPosition + offset))
                    availableDirections ~= direction;
            
            if(availableDirections.length == 0)
                return;
            
            wantedVelocity = grid.directionOffsets[availableDirections[uniform(0, $)]];
            eyesOffset = cast(vec2i)(wantedVelocity * vec2(2, 3));
            startMoving = true;
        }
    }
    
    override void render()
    {
        immutable x = cast(int)screenPosition.x;
        immutable y = cast(int)screenPosition.y;
        
        bodyTexture.setColorMod(
            cast(ubyte)color.r,
            cast(ubyte)color.g,
            cast(ubyte)color.b,
        );
        renderer.copy(eyesBackgroundTexture, x, y);
        renderer.copy(bodyTexture, x, y);
        renderer.copy(eyesTexture, x + eyesOffset.x, y + eyesOffset.y);
    }
}
