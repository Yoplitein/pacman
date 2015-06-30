import core.thread;
import std.experimental.logger;
import std.file;
import std.math;
import std.random;
import std.string;

import gfm.logger;
import gfm.sdl2;
import gfm.opengl;

import pacman;
import pacman.ghost;
import pacman.globals;
import pacman.grid;
import pacman.player;
import pacman.texture;
import pacman.renderer;
import pacman.levelgen;

SDL2Texture backgroundTexture;

void main()
{
    stdlog = new ConsoleLogger;
    sdl = new SDL2(stdlog); scope(exit) sdl.close;
    sdlImage = new SDLImage(sdl, IMG_INIT_PNG); scope(exit) sdlImage.close;
    opengl = new OpenGL(stdlog); scope(exit) opengl.close;
    window = new SDL2Window(
        sdl,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT,
        SDL_WINDOW_OPENGL
    ); scope(exit) window.close;
    /*renderer = new SDL2Renderer(
        window,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    ); scope(exit) renderer.close;*/
    //backgroundTexture = get_texture("res/background.png");
    
    opengl.reload;
    init_opengl;
    
    renderer = new Renderer; scope(exit) renderer.close;
    grid = new Grid;
    player = new Player;
    ghost = new Ghost(vec3i(255, 0, 255));
    uint frames;
    real lastFrameTime = 0;
    real lastTitleUpdate = 0;
    
    void regenerate_level()
    {
        generate_level;
        player.set_position(grid.playerSpawn);
        ghost.set_position(grid.ghostSpawns[0]);
    }
    
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
            window.setTitle("%d fps   %f dt".format(frames, timeDelta));
            
            frames = 0;
            lastTitleUpdate = timeSeconds;
        }
        
        if(sdl.keyboard.testAndRelease(SDLK_g))
            regenerate_level;
        
        glClear(GL_COLOR_BUFFER_BIT);
        //draw_background;
        renderer.update;
        grid.render;
        ghost.update;
        ghost.render;
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
