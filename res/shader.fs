#version 130
#define TEXTURE_SIZE 32u

in vec2 fragmentTextureCoordinate;
flat in uint fragmentTextureIndex;
in vec3 fragmentColorMask;

out vec4 outColor;

uniform uint atlasSizePixels; //size of the atlas in pixels
uniform uint atlasSizeTiles; //size of the atlas in TEXTURE_SIZE tiles
uniform float atlasTileSizeFloating; //size of a tile on the atlas in floating coords
uniform sampler2D activeTexture;

void main()
{
    uvec2 tileCoords = uvec2(
        fragmentTextureIndex % atlasSizeTiles,
        fragmentTextureIndex / atlasSizeTiles
    );
    uvec2 pixelCoords = tileCoords * TEXTURE_SIZE;
    vec2 floatingCoords = pixelCoords / float(atlasSizePixels);
    vec2 flippedCoords = vec2(fragmentTextureCoordinate.x, 1 -fragmentTextureCoordinate.y);
    vec2 finalCoords = floatingCoords + flippedCoords * atlasTileSizeFloating;
    
    outColor = vec4(fragmentColorMask, 1.0) * texture(activeTexture, finalCoords);
}
