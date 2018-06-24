
Loading a texture (INIT script)
--------------------------------------------------------------

local demo_dir = gh_utils.get_demo_dir()  
local abs_path = 0
local PF_U8_RGB = 1
local PF_U8_RGBA = 3
local pixel_format = PF_U8_RGBA
local gen_mipmaps = 1
local compressed_texture = 0
tex0 = gh_texture.create_from_file_v6(demo_dir .. "./data/tex17.jpg", pixel_format, gen_mipmaps, compressed_texture)



Binding a texture (FRAME script)
--------------------------------------------------------------

gh_texture.bind(tex0, 0)
gh_gpu_program.uniform1i(shadertoy_prog, "iChannel0", 0)



Texture in the pixel shader
-----------------------------

uniform sampler2D iChannel0; 

vec4 c = texture2D(iChannel0, uv);
