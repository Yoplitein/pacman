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

SDL_PixelFormat get_format_data(uint format)
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

SDL2Texture load_texture(string path, uint pixelFormat = SDL_PIXELFORMAT_RGBA8888)
{
    auto formatData = get_format_data(pixelFormat);
    auto surfaceRaw = sdlImage.load("res/player0.png"); scope(exit) surfaceRaw.close;
    auto surface = surfaceRaw.convert(&formatData); scope(exit) surface.close;
    auto result = new SDL2Texture(
        renderer,
        pixelFormat,
        SDL_TEXTUREACCESS_STATIC,
        surface.width, surface.height
    );
    
    result.updateTexture(surface.pixels, surface.pitch);
    result.setBlendMode(SDL_BLENDMODE_BLEND);
    
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
    texture = load_texture("res/player0.png");
    
    while(true)
    {
        sdl.processEvents;
        
        if(sdl.keyboard.isPressed(SDLK_ESCAPE))
            break;
        
        renderer.clear;
        renderer.copy(texture, 100, 100);
        renderer.present;
    }
}
