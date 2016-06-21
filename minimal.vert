#version 450 core

layout(location = 0) in vec2 vertexPosition;
layout(location = 1) in vec2 vertexTexCoord;
layout(location = 2) in vec4 vertexColor;

out vec2 UV;
out vec4 color;

layout(location = 0) uniform mat4 MVPmatrix;

void main(){
  vec4 v = MVPmatrix * vec4(vertexPosition, 0.0, 1.0);
  gl_Position = v;
  UV = vertexTexCoord;
  color = vertexColor;
}
