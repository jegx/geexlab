
mouse_texture = 0
mouse_quad = 0
mouse_prog = 0
mouse_quad_width = 20
mouse_quad_height = 20

function mouse_init_gpu_program()

    local vs_gl3=" \
  in vec4 gxl3d_Position;\
  in vec4 gxl3d_TexCoord0;\
  uniform mat4 gxl3d_ModelViewProjectionMatrix; \
  out vec4 Vertex_UV;\
  void main() \
  { \
    gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
    Vertex_UV = gxl3d_TexCoord0;\
  }"

    local ps_gl3=" \
  uniform sampler2D tex0;\
  uniform vec4 color;\
  in vec4 Vertex_UV;\
  out vec4 FragColor;\
  void main() \
  { \
    vec2 uv = Vertex_UV.xy;\
    uv.y *= -1.0;\
    vec4 t = texture(tex0,uv);\
    if ((t.r == 1.0) && (t.g < 1.0) && (t.g < 1.0))\
      FragColor = color;  \
    else \
     discard;\
  }"
    
    local vs_gl2=" \
  varying vec4 Vertex_UV;\
  void main() \
  { \
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\
    Vertex_UV = gl_MultiTexCoord0;\
  }"

    local ps_gl2=" \
  uniform sampler2D tex0;\
  uniform vec4 color;\
  varying vec4 Vertex_UV;\
  void main() \
  { \
    vec2 uv = Vertex_UV.xy;\
    uv.y *= -1.0;\
    vec4 t = texture2D(tex0,uv);\
    if ((t.r == 1.0) && (t.g < 1.0) && (t.g < 1.0))\
      gl_FragColor = color;  \
    else \
     discard;\
  }"

    local vs_gles2=" \
  attribute vec4 gxl3d_Position;\
  attribute vec4 gxl3d_TexCoord0;\
  uniform mat4 gxl3d_ModelViewProjectionMatrix; \
  varying vec4 Vertex_UV;\
  void main() \
  { \
    gl_Position = gxl3d_ModelViewProjectionMatrix * gxl3d_Position;\
    Vertex_UV = gxl3d_TexCoord0;\
  }"

    local ps_gles2=" \
  uniform sampler2D tex0;\
  uniform highp vec4 color;\
  varying highp vec4 Vertex_UV;\
  void main() \
  { \
    highp vec2 uv = Vertex_UV.xy;\
    uv.y *= -1.0;\
    highp vec4 t = texture2D(tex0,uv);\
    if ((t.r == 1.0) && (t.g < 1.0) && (t.b < 1.0))\
      gl_FragColor = color;  \
    else \
     discard;\
  }"


  if (gh_renderer.is_opengl_es() == 1) then
    vs = vs_gles2
    ps = ps_gles2
  else
    vs = vs_gl3
    ps = ps_gl3
  end  

  mouse_prog = gh_gpu_program.create_v2("mouse_prog", vs, ps)
  gh_gpu_program.uniform1i(mouse_prog, "tex0", 0)
end





function mouse_init()
  if (mouse_texture == 0) then
    local lib_dir = gh_utils.get_scripting_libs_dir() 		
    local PF_U8_RGBA = 3
    mouse_texture = gh_texture.create_from_file(lib_dir .. "common/mouse-pointer-md.png", PF_U8_RGBA, 1)
  end
  
  if (mouse_quad == 0) then
    mouse_quad = gh_mesh.create_quad(mouse_quad_width, mouse_quad_height)
  end
  
  if (mouse_prog == 0) then
    mouse_init_gpu_program()
  end
end  


function mouse_draw(ortho_cam, x, y)
  gh_camera.bind(ortho_cam)
  gh_renderer.set_depth_test_state(0)
  gh_texture.bind(mouse_texture, 0)
  gh_gpu_program.bind(mouse_prog)
  gh_gpu_program.uniform4f(mouse_prog, "color", 1.0, 1.0, 1.0, 1.0)
  gh_object.set_position(mouse_quad, x + mouse_quad_width/2, y - mouse_quad_height/2, 0)
  gh_object.render(mouse_quad)
end
