#version 130

in vec2 coordinate;
in vec2 textureCoordinate;

out vec2 fragmentTextureCoordinate;
out vec3 fragColor;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform vec2 position;
uniform float rotation;

void main()
{
    fragmentTextureCoordinate = textureCoordinate;
    vec4 coordinate4 = vec4(coordinate, 0.0, 1.0);
    gl_Position = projection * view * model * coordinate4;
}
