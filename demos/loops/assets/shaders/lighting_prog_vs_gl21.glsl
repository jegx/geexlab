#version 120
uniform mat4 gxl3d_ModelViewProjectionMatrix; // GeeXLab built-in uniform.
uniform mat4 gxl3d_ModelViewMatrix; // GeeXLab built-in uniform.
uniform mat4 gxl3d_ViewMatrix; // GeeXLab built-in uniform.
uniform vec4 light0_position;
uniform vec4 light1_position;
varying vec4 Vertex_C;
varying vec4 Vertex_N;
varying vec4 Vertex_L[2];
varying vec4 Vertex_E;
varying vec4 Vertex_UV;
void main()
{
  gl_Position = gxl3d_ModelViewProjectionMatrix * gl_Vertex;
  Vertex_C = gl_Color;
  Vertex_UV = gl_MultiTexCoord0;
  Vertex_N = gxl3d_ModelViewMatrix * vec4(gl_Normal, 0.0);
  vec4 view_vertex = gxl3d_ModelViewMatrix * gl_Vertex;
  vec4 LP = gxl3d_ViewMatrix * light0_position;
  Vertex_L[0] = LP - view_vertex;
  LP = gxl3d_ViewMatrix * light1_position;
  Vertex_L[1] = LP - view_vertex;
  Vertex_E = -view_vertex;
}

