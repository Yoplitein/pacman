import std.experimental.logger;
import std.string;

import gfm.logger;
import gfm.sdl2;

import pacman.player;
import pacman.globals;
import pacman.grid;

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
    grid = new Grid; scope(exit) grid.destroy;
    player = new Player; scope(exit) player.destroy;
    uint frames;
    real lastFrameTime = 0;
    real lastTitleUpdate = 0;
    
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
        grid.render;
        player.update;
        player.render;
        renderer.present;
    }
}
