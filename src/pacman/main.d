import std.experimental.logger;
import std.string;

import gfm.logger;
import gfm.sdl2;

import pacman.player;
import pacman.globals;

enum WIDTH = 800;
enum HEIGHT = 600;

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
        SDL_RENDERER_ACCELERATED
    ); scope(exit) renderer.close;
    Player player = new Player; scope(exit) player.destroy;
    
    while(true)
    {
        sdl.processEvents;
        
        if(sdl.keyboard.isPressed(SDLK_ESCAPE))
            break;
        
        renderer.clear;
        player.update;
        player.render;
        //renderer.copy(texture, 100, 100);
        renderer.present;
    }
}
