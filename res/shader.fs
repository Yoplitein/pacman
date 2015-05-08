#version 130

in vec2 fragmentTextureCoordinate;

out vec4 outColor;

uniform sampler2D activeTexture;

void main()
{
    vec2 correctedCoordinate = vec2(fragmentTextureCoordinate.x, 1 - fragmentTextureCoordinate.y);
    outColor = texture(activeTexture, correctedCoordinate);
}
