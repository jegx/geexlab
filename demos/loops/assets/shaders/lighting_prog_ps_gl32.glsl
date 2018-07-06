#version 150
uniform sampler2D tex0;
in vec4 Vertex_C;
in vec4 Vertex_N;
in vec4 Vertex_L[2];
in vec4 Vertex_E;
in vec4 Vertex_UV;
uniform vec4 emissive;
uniform vec4 light0_diffuse;
uniform vec4 light1_diffuse;
uniform vec4 light_ambient;
uniform vec4 light_specular;
uniform vec4 material_diffuse;
uniform vec4 material_ambient;
uniform vec4 material_specular; 
uniform float material_shininess;
uniform vec4 uv_tiling;
out vec4 Out_Color;
void main()
{
  vec2 uv = Vertex_UV.xy * uv_tiling.xy;
  //uv.y *= -1;
  vec4 tex_color = texture(tex0, uv);
  //vec4 tex_color = vec4(1.0);

  float rgb_avg = (tex_color.r+tex_color.g+tex_color.b)/3.0;

  vec3 final_color = material_ambient.rgb * light_ambient.rgb * tex_color.rgb; 
  vec3 N = normalize(Vertex_N.xyz);
  vec3 L = normalize(Vertex_L[0].xyz);
  float lambertTerm = dot(N,L);
  if (lambertTerm > 0.0)
  {
    final_color += material_diffuse.rgb * light0_diffuse.rgb * tex_color.rgb * lambertTerm;
    vec3 E = normalize(Vertex_E.xyz);
    vec3 R = reflect(-L, N);
    float specular = pow( max(dot(R, E), 0.0), material_shininess);
    final_color += material_specular.rgb * light_specular.rgb * specular;
  }


  L = normalize(Vertex_L[1].xyz);
  lambertTerm = dot(N,L);
  if (lambertTerm > 0.0)
  {
    final_color += material_diffuse.rgb * light1_diffuse.rgb * tex_color.rgb * lambertTerm;
    vec3 E = normalize(Vertex_E.xyz);
    vec3 R = reflect(-L, N);
    float specular = pow( max(dot(R, E), 0.0), material_shininess);
    final_color += material_specular.rgb * light_specular.rgb * specular;
  }

  Out_Color.rgb = final_color * Vertex_C.rgb + emissive.rgb;
  //Out_Color.rgb = vec3(1.0, 0.0, 0.0);
  Out_Color.a = rgb_avg;
}
