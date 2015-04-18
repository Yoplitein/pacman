import std.experimental.logger;
import std.math;
import std.random;
import std.string;

import gfm.logger;
import gfm.sdl2;

import pacman;
import pacman.player;
import pacman.globals;
import pacman.grid;
import pacman.texture;

SDL2Texture backgroundTexture;

void main()
{
    stdlog = new ConsoleLogger;
    sdl = new SDL2(stdlog); scope(exit) sdl.close;
    sdlImage = new SDLImage(sdl, IMG_INIT_PNG); scope(exit) sdlImage.close;
    window = new SDL2Window(
        sdl,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT,
        0
    ); scope(exit) window.close;
    renderer = new SDL2Renderer(
        window,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    ); scope(exit) renderer.close;
    backgroundTexture = load_texture("res/background.png"); scope(exit) backgroundTexture.close;
    grid = new Grid; scope(exit) grid.destroy;
    player = new Player; scope(exit) player.destroy;
    uint frames;
    real lastFrameTime = 0;
    real lastTitleUpdate = 0;
    
    grid.load("res/map.json");
    
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
        
        renderer.clear;
        reset_viewport;
        draw_background;
        center_viewport;
        grid.render;
        player.update;
        player.render;
        renderer.present;
    }
}

void reset_viewport()
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
}

void draw_background()
{
    immutable xMax = cast(int)ceil(WIDTH / cast(real)TEXTURE_SIZE);
    immutable yMax = cast(int)ceil(HEIGHT / cast(real)TEXTURE_SIZE);
    
    foreach(y; 0 .. yMax)
        foreach(x; 0 .. xMax)
            renderer.copy(backgroundTexture, x * TEXTURE_SIZE, y * TEXTURE_SIZE);
}
