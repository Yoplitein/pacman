module pacman.gl.texture;

import std.algorithm;
import std.experimental.logger;
import std.file;
import std.math;

import gfm.opengl;
import gfm.sdl2;

import pacman.globals;

private TextureData missingTexture;
private TextureData[] queuedTextures; //textures to be stitched
package GLTexture2D textureAtlas; //the texture that results from stitching
package uint currentTextureIndex; //counter for TextureData.index
package uint atlasSizeTiles; //the width and height of the atlas in TEXTURE_SIZE chunks
package uint atlasSizePixels; //the width and height of the atlas in pixels
private bool texturesStitched; //whether stitching has been done

struct TextureData
{
    string path;
    package uint index;
}

private SDL_PixelFormat get_format_data()
{
    version(LittleEndian)
        enum format = SDL_PIXELFORMAT_ABGR8888;
    else version(BigEndian)
        enum format = SDL_PIXELFORMAT_RGBA8888;
    else
        static assert(false, "Unknown architecture");
    
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

private SDL2Surface load_image(string path, SDL_PixelFormat formatData)
{
    if(!path.exists)
        fatal("Attempted to load missing image: ", path);
    
    auto rawSurface = sdlImage.load(path);
    scope(exit) rawSurface.destroy;
    auto surface = rawSurface.convert(&formatData);
    
    assert(surface.width == TEXTURE_SIZE);
    assert(surface.height == TEXTURE_SIZE);
    
    return surface;
}

private TextureData queue_texture(string path)
{
    if(texturesStitched)
        fatal("Attempting to queue texture for stitching too late");
    
    info("Queuing texture ", path);
    
    auto data = TextureData(path, currentTextureIndex++);
    queuedTextures ~= data;
    
    return data;
}

TextureData get_texture(string path)
{
    if(missingTexture == TextureData.init)
        missingTexture = queue_texture("res/missing.png");
    
    if(!path.exists)
    {
        warningf("Texture %s does not exist, using fallback texture", path);
        
        return missingTexture;
    }
    
    auto search = queuedTextures.filter!(tex => tex.path == path);
    
    if(!search.empty)
        return search.front;
    else
        return queue_texture(path);
}

void stitch_textures()
{
    if(texturesStitched)
        fatal("Attempting to re-stitch textures");
    
    texturesStitched = true;
    auto formatData = get_format_data;
    atlasSizeTiles = cast(int)sqrt(cast(real)queuedTextures.length) + 1;
    atlasSizePixels = TEXTURE_SIZE * atlasSizeTiles;
    
    infof("Have %s textures to stitch", queuedTextures.length);
    infof("Final texture size: %s²", atlasSizeTiles * TEXTURE_SIZE);
    
    SDL2Surface stitched = new SDL2Surface(
        sdl,
        atlasSizePixels, //width
        atlasSizePixels, //height
        formatData.BitsPerPixel,
        formatData.Rmask,
        formatData.Gmask,
        formatData.Bmask,
        formatData.Amask,
    );
    scope(exit) stitched.destroy;
    
    foreach(int index, texture; queuedTextures)
    {
        texture.index = index;
        int x = index % atlasSizeTiles * TEXTURE_SIZE;
        int y = index / atlasSizeTiles * TEXTURE_SIZE;
        auto srcRect = SDL_Rect(0, 0, TEXTURE_SIZE, TEXTURE_SIZE);
        auto dstRect = SDL_Rect(x, y, TEXTURE_SIZE, TEXTURE_SIZE);
        SDL2Surface image = load_image(texture.path, formatData);
        scope(exit) image.destroy;
        
        SDL_BlitSurface(
            image.handle,
            &srcRect,
            stitched.handle,
            &dstRect,
        );
    }
    
    textureAtlas = new GLTexture2D(opengl);
    
    textureAtlas.setMinFilter(GL_NEAREST_MIPMAP_NEAREST);
    textureAtlas.setMagFilter(GL_NEAREST);
    textureAtlas.setWrapS(GL_REPEAT);
    textureAtlas.setWrapT(GL_REPEAT);
    textureAtlas.setImage(0, GL_RGBA, stitched.width, stitched.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, stitched.pixels);
    textureAtlas.generateMipmap;
}

void close_textures()
{
    textureAtlas.destroy;
}
