module pacman.gl.texture;

import std.experimental.logger;
import std.file;

import gfm.opengl;
import gfm.sdl2;

import pacman.globals;

private TextureData missingTexture;
private TextureData[string] loadedTextures;

struct TextureData
{
    private GLTexture2D _texture;
    string path;
    int width;
    int height;
    
    @property GLTexture2D texture()
    {
        return _texture;
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

private TextureData load_texture(string path)
{
    if(!path.exists)
        fatal("Attempted to load missing texture: ", path);
    
    info("Caching texture ", path);
    
    version(LittleEndian)
        enum pixelFormat = SDL_PIXELFORMAT_ABGR8888;
    else version(BigEndian)
        enum pixelFormat = SDL_PIXELFORMAT_RGBA8888;
    else
        static assert(false, "Unknown architecture");
    
    auto formatData = get_format_data(pixelFormat);
    auto rawSurface = sdlImage.load(path);
    scope(exit) rawSurface.destroy;
    auto surface = rawSurface.convert(&formatData);
    scope(exit) surface.destroy;
    
    assert(surface.width == TEXTURE_SIZE);
    assert(surface.height == TEXTURE_SIZE);
    
    auto texture = new GLTexture2D(opengl);
    TextureData data = TextureData(
        texture,
        path,
        surface.width,
        surface.height
    );
    loadedTextures[path] = data;
    
    texture.setMinFilter(GL_NEAREST_MIPMAP_NEAREST);
    texture.setMagFilter(GL_NEAREST);
    texture.setWrapS(GL_REPEAT);
    texture.setWrapT(GL_REPEAT);
    texture.setImage(0, GL_RGBA, surface.width, surface.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, surface.pixels);
    texture.generateMipmap;
    
    return data;
}

TextureData get_texture(string path)
{
    if(!missingTexture.texture)
        missingTexture = load_texture("res/missing.png");
    
    if(!path.exists)
    {
        warningf("Texture %s does not exist, using fallback texture", path);
        
        return missingTexture;
    }
    
    auto textureData = path in loadedTextures;
    
    if(textureData)
        return *textureData;
    else
        return load_texture(path);
}

void close_textures()
{
    foreach(data; loadedTextures.values)
        data.texture.destroy;
}
