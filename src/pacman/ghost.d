module pacman.ghost;

import gfm.sdl2;

import pacman;
import pacman.creature;
import pacman.texture;
import pacman.globals;

final class Ghost: Creature
{
    static int textureRefcount = 0;
    static SDL2Texture bodyTexture;
    static SDL2Texture eyesTexture;
    static SDL2Texture eyesBackgroundTexture;
    bool drawBody = true;
    real lastSwitch = 0;
    vec3i color;
    
    this(vec3i color)
    {
        if(bodyTexture is null)
        {
            bodyTexture = load_texture("res/ghost_body.png");
            eyesTexture = load_texture("res/ghost_eyes.png");
            eyesBackgroundTexture = load_texture("res/ghost_eyes_background.png");
        }
        
        textureRefcount++;
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
        
        if(timeSeconds - lastSwitch > 0.25)
        {
            lastSwitch = timeSeconds;
            drawBody = !drawBody;
        }
    }
    
    override void render()
    {
        immutable vec2i screenPos = gridPosition * TILE_SIZE;
        
        bodyTexture.setColorMod(
            cast(ubyte)color.r,
            cast(ubyte)color.g,
            cast(ubyte)color.b,
        );
        renderer.copy(eyesBackgroundTexture, screenPos.x, screenPos.y);
        renderer.copy(bodyTexture, screenPos.x, screenPos.y);
        renderer.copy(eyesTexture, screenPos.x, screenPos.y);
    }
}
