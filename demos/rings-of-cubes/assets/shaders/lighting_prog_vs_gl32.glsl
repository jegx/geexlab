#version 150
in vec4 gxl3d_Position;
in vec4 gxl3d_Normal;
in vec4 gxl3d_TexCoord0;
in vec4 gxl3d_Color;
uniform mat4 gxl3d_ModelViewProjectionMatrix; // GeeXLab built-in uniform.
uniform mat4 gxl3d_ModelViewMatrix; // GeeXLab built-in uniform.
uniform mat4 gxl3d_ViewMatrix; // GeeXLab built-in uniform.
uniform vec4 light0_position;
uniform vec4 light1_position;
out vec4 Vertex_C;
out vec4 Vertex_N;
out vec4 Vertex_L[2];
out vec4 Vertex_E;
out vec4 Vertex_UV;
void main()
{
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;
  Vertex_C = gxl3d_Color;
  Vertex_UV = gxl3d_TexCoord0;
  Vertex_N = gxl3d_ModelViewMatrix * gxl3d_Normal;
  vec4 view_vertex = gxl3d_ModelViewMatrix * gxl3d_Position;
  vec4 LP = gxl3d_ViewMatrix * light0_position;
  Vertex_L[0] = LP - view_vertex;
  LP = gxl3d_ViewMatrix * light1_position;
  Vertex_L[1] = LP - view_vertex;
  Vertex_E = -view_vertex;
}

