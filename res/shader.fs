#version 130

in vec2 fragmentTextureCoordinate;

out vec4 outColor;

uniform sampler2D activeTexture;
uniform vec3 colorMask;

void main()
{
    vec2 correctedCoordinate = vec2(fragmentTextureCoordinate.x, 1 - fragmentTextureCoordinate.y);
    outColor = vec4(colorMask, 1.0) * texture(activeTexture, correctedCoordinate);
}
