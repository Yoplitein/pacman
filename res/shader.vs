#version 130

in vec2 coordinate;
in vec2 textureCoordinate;

out vec2 fragmentTextureCoordinate;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main()
{
    fragmentTextureCoordinate = textureCoordinate;
    vec4 coordinate4 = vec4(coordinate, 0.0, 1.0);
    gl_Position = projection * view * model * coordinate4;
}
