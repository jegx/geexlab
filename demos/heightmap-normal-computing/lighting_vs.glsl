
#version 150
in vec4 gxl3d_Position;
in vec4 gxl3d_TexCoord0;
in vec4 gxl3d_Normal;
out vec4 v_normal;
out vec4 v_lightdir;
out vec4 v_eyedir;
uniform mat4 gxl3d_ProjectionMatrix; // GeeXLab auto-uniform.
uniform mat4 gxl3d_ModelViewMatrix; // GeeXLab auto-uniform.
uniform mat4 gxl3d_ViewMatrix; // GeeXLab auto-uniform.
uniform vec4 light_position;



float f(float x, float z)
{
  return sin(x) * cos(z);
}



vec3 calc_normal(float x, float z)
{
  float eps = 0.0001;
  return normalize(vec3(
  f(x-eps, z) - f(x+eps, z), 
  2.0*eps,
  f(x, z-eps) - f(x, z+eps)
  ));
}



void main()
{
  vec4 P = gxl3d_Position;
  P.y = f(P.x, P.z);

  vec3 N = calc_normal(P.x, P.z);
 
  vec4 view_position = gxl3d_ModelViewMatrix * P;
  gl_Position = gxl3d_ProjectionMatrix * view_position;
  
  v_normal = gxl3d_ModelViewMatrix * vec4(N, 0.0);
  v_eyedir = -view_position;
  
  vec4 lp = gxl3d_ViewMatrix * light_position;
  v_lightdir = lp - view_position;
}
