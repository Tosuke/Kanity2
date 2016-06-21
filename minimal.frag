#version 450 core

in vec2 UV;

out vec4 outColor;

layout(location = 3) uniform sampler2D textureSampler;

void main(){
  vec4 color = texture(textureSampler, UV);
  color.a = 0.3;
  //color = vec4(1, 1, 1, 1);
  outColor = color;
}
