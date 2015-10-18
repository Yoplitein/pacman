#version 130

in vec2 fragmentTextureCoordinate;
in vec3 fragmentColorMask;

out vec4 outColor;

uniform sampler2D activeTexture;

void main()
{
    outColor = vec4(fragmentColorMask, 1.0) * texture(activeTexture, fragmentTextureCoordinate);
}
