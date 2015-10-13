module pacman.main;

import core.thread;
import std.experimental.logger;
import std.file;
import std.math;
import std.random;
import std.string;

import gfm.logger;
import gfm.opengl;
import gfm.sdl2;

import pacman.entity.ghost;
import pacman.entity.grid;
import pacman.entity.player;
import pacman.gl.renderer;
import pacman.gl.texture;
import pacman.globals;
import pacman.levelgen;
import pacman;

SDL2Texture backgroundTexture;

void main()
{
    sharedLog = new ConsoleLogger;
    sdl = new SDL2(sharedLog);
    scope(exit) sdl.destroy;
    sdlImage = new SDLImage(sdl, IMG_INIT_PNG);
    scope(exit) sdlImage.destroy;
    opengl = new OpenGL(sharedLog);
    scope(exit) opengl.destroy;
    window = new SDL2Window(
        sdl,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT,
        SDL_WINDOW_OPENGL
    );
    scope(exit) window.destroy;
    /*renderer = new SDL2Renderer(
        window,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );
    scope(exit) renderer.destroy;*/
    //backgroundTexture = get_texture("res/background.png");
    
    opengl.reload;
    init_opengl;
    
    renderer = new Renderer;
    scope(exit) renderer.close;
    grid = new Grid;
    player = new Player;
    ghosts = [
        new Ghost(vec3f(1.00, 0.00, 0.00), Ghost.AI_WANDER),
        new Ghost(vec3f(0.00, 1.00, 0.87), Ghost.AI_CHASE),
        new Ghost(vec3f(1.00, 0.72, 0.87), Ghost.AI_CHASE),
        new Ghost(vec3f(1.00, 0.72, 0.27), Ghost.AI_WANDER),
    ];
    uint frames;
    real lastFrameTime = 0;
    real lastTitleUpdate = 0;
    bool empoweredStateSeen;
    
    void regenerate_level()
    {
        generate_level;
        player.reset;
        player.set_position(grid.playerSpawn);
        
        foreach(index, ghost; ghosts)
        {
            ghost.reset;
            ghost.set_position(grid.ghostSpawns[index]);
        }
    }
    
    stitch_textures;
    regenerate_level;
    renderer.program.uniform("model").set(
        mat4.translation(vec3f(15, 15, 0)) *
        mat4.scaling(vec3f(200, 200, 1))
    );
    renderer.program.uniform("activeTexture").set(0);
    
    while(true)
    {
        timeSeconds = SDL_GetTicks() / 1000.0L;
        timeDelta = timeSeconds - lastFrameTime;
        lastFrameTime = timeSeconds;
        frames++;
        
        sdl.processEvents;
        
        if(sdl.wasQuitRequested || sdl.keyboard.isPressed(SDLK_ESCAPE))
            break;
        
        if(timeSeconds - lastTitleUpdate >= 1)
        {
            window.setTitle("%d fps   %f dt   %d points".format(frames, timeDelta, player.score));
            
            frames = 0;
            lastTitleUpdate = timeSeconds;
        }
        
        if(sdl.keyboard.testAndRelease(SDLK_g))
            regenerate_level;
        
        if(sdl.keyboard.testAndRelease(SDLK_e))
            player.empowered = true;
        
        if(player.dead)
        {
            if(player.deadTime >= Player.DEATH_TIME)
                regenerate_level;
        }
        
        if(player.empowered)
        {
            if(!empoweredStateSeen) //player is freshly empowered
            {
                foreach(ghost; ghosts)
                    ghost.set_scared();
                
                empoweredStateSeen = true;
            }
        }
        else
        {
            if(empoweredStateSeen) //player is no longer empowered
            {
                foreach(ghost; ghosts)
                    ghost.set_not_scared;
                
                empoweredStateSeen = false;
            }
        }
        
        glClear(GL_COLOR_BUFFER_BIT);
        //draw_background;
        renderer.update;
        grid.render;
        
        foreach(ghost; ghosts)
        {
            ghost.update;
            ghost.render;
        }
        
        player.update;
        player.render;
        //renderer.draw;
        window.swapBuffers;
    }
    
    close_textures;
}

void init_opengl()
{
    glClearColor(0, 0, 0, 1);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

/*void reset_viewport()
{
    renderer.setViewport(0, 0, WIDTH, HEIGHT);
}

void center_viewport()
{
    renderer.setViewport(
        WIDTH / 2 - cast(int)player.screenPosition.x,
        HEIGHT / 2 - cast(int)player.screenPosition.y,
        WIDTH, HEIGHT
    );
}*/

/*void draw_background()
{
    immutable xMax = cast(int)ceil(WIDTH / cast(real)TEXTURE_SIZE);
    immutable yMax = cast(int)ceil(HEIGHT / cast(real)TEXTURE_SIZE);
    
    foreach(y; 0 .. yMax)
        foreach(x; 0 .. xMax)
            renderer.copy(backgroundTexture, x * TEXTURE_SIZE, y * TEXTURE_SIZE);
}*/
