
#version 150
in vec4 v_normal;
in vec4 v_lightdir;
in vec4 v_eyedir;
out vec4 FragColor;
void main()
{
  
  vec3 albedo = vec3(0.9, 0.7, 0.5);
  vec3 N = normalize(v_normal.xyz);
  vec3 L = normalize(v_lightdir.xyz);
  float NdotL = max(dot(N, L), 0.0);
  vec3 color = albedo * vec3(0.4);
  color += albedo * NdotL;
  
  vec3 E = normalize(v_eyedir.xyz);
  vec3 R = reflect(-L, N);
  float specular = pow(max(dot(R, E), 0.0), 64.0);
  color += vec3(0.8, 0.8, 0.8) * specular;	
 
  
  FragColor.rgb = color;
  FragColor.a = 1.0;
}
