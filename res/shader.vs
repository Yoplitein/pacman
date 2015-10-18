#version 130

in vec2 coordinate;
in vec2 textureCoordinate;
in vec4 maskAndIndex; //color mask and texture index in single vector to work around gfm limitations
//model matrix unpacked as four vec4s, again working around gfm limitations
in vec4 modelColumn1;
in vec4 modelColumn2;
in vec4 modelColumn3;
in vec4 modelColumn4;

out vec2 fragmentTextureCoordinate;
flat out uint fragmentTextureIndex;
out vec3 fragmentColorMask;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    mat4 model = mat4(
        modelColumn1,
        modelColumn2,
        modelColumn3,
        modelColumn4
    );
    fragmentTextureCoordinate = textureCoordinate;
    fragmentTextureIndex = uint(maskAndIndex.w);
    fragmentColorMask = maskAndIndex.rgb;
    vec4 coordinate4 = vec4(coordinate, 0.0, 1.0);
    gl_Position = projection * view * model * coordinate4;
}
