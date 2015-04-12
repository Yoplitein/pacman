import std.experimental.logger;

import gfm.logger;
import gfm.sdl2;

enum WIDTH = 800;
enum HEIGHT = 600;

SDL2 sdl;
SDLImage sdlImage;
SDL2Window window;
SDL2Renderer renderer;
SDL2Texture texture;

SDL_PixelFormat format_from_enum(uint format)
{
    SDL_PixelFormat result;
    int bpp;
    uint r;
    uint g;
    uint b;
    uint a;
    
    SDL_PixelFormatEnumToMasks(
        format,
        &bpp,
        &r,
        &g,
        &b,
        &a
    );
    
    result.format = format;
    result.BitsPerPixel = cast(ubyte)bpp;
    result.BytesPerPixel = cast(ubyte)bpp / 8;
    result.Rmask = r;
    result.Gmask = g;
    result.Bmask = b;
    result.Amask = a;
    
    return result;
}

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
    auto format = format_from_enum(SDL_PIXELFORMAT_RGBA8888);
    auto playerTextureRaw = sdlImage.load("res/player0.png"); scope(exit) playerTextureRaw.close;
    auto playerTexture = playerTextureRaw.convert(&format); scope(exit) playerTexture.close;
    texture = new SDL2Texture(
        renderer,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_STATIC,
        playerTexture.width, playerTexture.height
    );
    
    texture.updateTexture(playerTexture.pixels, playerTexture.pitch);
    texture.setBlendMode(SDL_BLENDMODE_BLEND);
    
    while(true)
    {
        sdl.processEvents;
        
        if(sdl.keyboard.isPressed(SDLK_ESCAPE))
            break;
        
        renderer.clear;
        renderer.copy(texture, 0, 0);
        renderer.present;
    }
}
