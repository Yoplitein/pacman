#version 130
#define TEXTURE_SIZE 32u

in vec2 coordinate;
in vec2 textureCoordinate;
in vec4 maskAndIndex; //color mask and texture index in single vector to work around gfm limitations
//model matrix unpacked as four vec4s, again working around gfm limitations
in vec4 modelColumn1;
in vec4 modelColumn2;
in vec4 modelColumn3;
in vec4 modelColumn4;

out vec2 fragmentTextureCoordinate;
out vec3 fragmentColorMask;

uniform mat4 projection;
uniform mat4 view;
uniform uint atlasSizePixels; //size of the atlas in pixels
uniform uint atlasSizeTiles; //size of the atlas in TEXTURE_SIZE tiles
uniform float atlasTileSizeFloating; //size of a tile on the atlas in floating coords

void main()
{
    mat4 model = mat4(
        modelColumn1,
        modelColumn2,
        modelColumn3,
        modelColumn4
    );
    vec4 coordinate4 = vec4(coordinate, 0.0, 1.0);
    gl_Position = projection * view * model * coordinate4;
    
    uint index = uint(maskAndIndex.w);
    uvec2 tileCoords = uvec2(
        index % atlasSizeTiles,
        index / atlasSizeTiles
    );
    uvec2 pixelCoords = tileCoords * TEXTURE_SIZE;
    vec2 floatingCoords = pixelCoords / float(atlasSizePixels);
    vec2 flippedCoords = vec2(textureCoordinate.x, 1 -textureCoordinate.y);
    fragmentTextureCoordinate = floatingCoords + flippedCoords * atlasTileSizeFloating;
    
    fragmentColorMask = maskAndIndex.rgb;
}
