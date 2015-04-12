import std.experimental.logger;
import std.string;

import gfm.logger;
import gfm.sdl2;

enum WIDTH = 800;
enum HEIGHT = 600;

SDL2 sdl;
SDLImage sdlImage;
SDL2Window window;
SDL2Renderer renderer;
SDL2Texture texture;
uint now;

class Player
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 15;
    SDL2Texture[] animationFrames;
    SDL2Texture activeTexture;
    uint textureIndex;
    bool animate = true;
    bool increment = true;
    uint lastAnimationStep;
    
    this()
    {
        foreach(index; 0 .. NUM_TEXTURES)
            animationFrames ~= load_texture("res/player%d.png".format(index));
        
        activeTexture = animationFrames[0];
    }
    
    ~this()
    {
        foreach(texture; animationFrames)
            texture.close;
    }
    
    void update()
    {
        if(!animate)
            return;
        
        if(now - lastAnimationStep > ANIMATION_DELAY)
        {
            if(increment)
                textureIndex++;
            else
                textureIndex--;
            
            if(textureIndex == 0 || textureIndex == animationFrames.length - 1)
                increment = !increment;
            
            activeTexture = animationFrames[textureIndex];
            lastAnimationStep = now;
        }
    }
    
    void render()
    {
        renderer.copy(activeTexture, 100, 100);
    }
}

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
    info("Loading texture ", path);
    
    auto formatData = get_format_data(pixelFormat);
    auto surfaceRaw = sdlImage.load(path); scope(exit) surfaceRaw.close;
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
    Player player = new Player; scope(exit) player.destroy;
    
    while(true)
    {
        sdl.processEvents;
        
        if(sdl.keyboard.isPressed(SDLK_ESCAPE))
            break;
        
        now = SDL_GetTicks();
        
        renderer.clear;
        player.update;
        player.render;
        //renderer.copy(texture, 100, 100);
        renderer.present;
    }
}
