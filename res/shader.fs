#version 130
#define TEXTURE_SIZE 32u

in vec2 fragmentTextureCoordinate;

out vec4 outColor;

uniform uint atlasSizePixels; //size of the atlas in pixels
uniform uint atlasSizeTiles; //size of the atlas in TEXTURE_SIZE tiles
uniform float atlasTileSizeFloating; //size of a tile on the atlas in floating coords
uniform uint index; //index into the atlas for the tile to use
uniform sampler2D activeTexture;
uniform vec3 colorMask;

void main()
{
    uvec2 tileCoords = uvec2(
        index % atlasSizeTiles,
        index / atlasSizeTiles
    );
    uvec2 pixelCoords = tileCoords * TEXTURE_SIZE;
    vec2 floatingCoords = pixelCoords / float(atlasSizePixels);
    vec2 flippedCoords = vec2(fragmentTextureCoordinate.x, 1 -fragmentTextureCoordinate.y);
    vec2 finalCoords = floatingCoords + flippedCoords * atlasTileSizeFloating;
    
    outColor = vec4(colorMask, 1.0) * texture(activeTexture, finalCoords);
}
