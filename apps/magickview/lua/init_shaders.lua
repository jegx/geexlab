
  
  
    local vertex_color_vs_gl2="\
#version 120\
void main()\
{\
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex; \
  gl_FrontColor = gl_Color;\
}"

  local vertex_color_ps_gl2=" \
#version 120\
void main()\
{\
  gl_FragColor = gl_Color;\
}"


    local vertex_color_vs_gles2=" \
attribute vec4 gxl3d_Position; \
attribute vec4 gxl3d_Color; \
uniform mat4 gxl3d_ModelViewProjectionMatrix; \
varying vec4 Vertex_Color;\
void main()\
{\
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  Vertex_Color = gxl3d_Color;\
}"

  local vertex_color_ps_gles2=" \
varying highp vec4 Vertex_Color; \
void main()\
{\
  gl_FragColor = Vertex_Color;\
}"



local vs = ""
local ps = ""

--[[
-- TODO
--
if (gh_renderer.is_opengl_es() == 1) then
  vs = vs_gles2
  ps = ps_gles2
else
  if (gh_renderer.get_api_version_major() < 3) then
    vs = vs_gl2
    ps = ps_gl2
  else
    if (gh_renderer.get_api_version_major() == 3) then
    if (gh_renderer.get_api_version_minor() < 2) then
      vs = vs_gl30
      ps = ps_gl30
    else
      vs = vs_gl32
      ps = ps_gl32
    end
    end
    if (gh_renderer.get_api_version_minor() > 3) then
      vs = vs_gl32
      ps = ps_gl32
    end
  end
end
--]]

if (gh_renderer.is_opengl_es() == 1) then
  vs = vertex_color_vs_gles2
  ps = vertex_color_ps_gles2
else
  vs = vertex_color_vs_gl2
  ps = vertex_color_ps_gl2
end  

vertex_color_prog = gh_gpu_program.create_v2("vertex_color_prog", vs, ps)










    local texture_vs_gl2="\
#version 120\
void main()\
{\
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex; \
  gl_TexCoord[0] = gl_MultiTexCoord0;\
}"

  local texture_ps_gl2=" \
#version 120\
uniform sampler2D tex0;\
void main()\
{\
  vec2 uv = gl_TexCoord[0].xy;\
  uv.y *= -1.;\
  vec4 c = texture2D(tex0, uv);\
  gl_FragColor = c;\
}"


    local texture_vs_gles2=" \
attribute vec4 gxl3d_Position; \
attribute vec4 gxl3d_TexCoord0; \
uniform mat4 gxl3d_ModelViewProjectionMatrix; // GeeXLab built-in uniform.\
varying vec4 Vertex_UV;\
void main()\
{\
  gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
  Vertex_UV = gxl3d_TexCoord0;\
}"

  local texture_ps_gles2=" \
precision highp float;\
uniform sampler2D tex0;\
varying vec4 Vertex_UV;\
void main()\
{\
  vec2 uv = Vertex_UV.xy;\
  uv.y *= -1.0;\
  vec4 c = texture2D(tex0, uv);\
  gl_FragColor = c;\
}"


if (gh_renderer.is_opengl_es() == 1) then
  vs = texture_vs_gles2
  ps = texture_ps_gles2
else
  vs = texture_vs_gl2
  ps = texture_ps_gl2
end  

texture_prog = gh_gpu_program.create_v2("texture_prog", vs, ps)

gh_gpu_program.uniform1i(phong_tex_prog, "tex0", 0)
