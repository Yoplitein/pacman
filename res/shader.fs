#version 130

in vec2 fragmentTextureCoordinate;

out vec4 outColor;

uniform sampler2D activeTexture;

void main()
{
    outColor = texture(activeTexture, fragmentTextureCoordinate);
}
