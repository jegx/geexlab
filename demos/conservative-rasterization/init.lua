
local demo_dir = gh_utils.get_demo_dir()
local lib_dir = gh_utils.get_scripting_libs_dir()     
dofile(lib_dir .. "lua/imgui.lua")    



gh_renderer.set_vsync(1)

winW, winH = gh_window.getsize(0)
    


-- Create a render target
--
-- The simplest way:
--rt01 = gh_render_target.create(32, 32);


---[[
-- A more complicated way that allows more control:
local num_color_targets = 1
local pf = 3 -- PF_U8_RGBA
local linear_filtering = 0
local clamp_addressing = 1
local samples = 0
local create_depth_texture = 0
rt01 = gh_render_target.create_ex_v4(32, 32, num_color_targets, pf, linear_filtering, clamp_addressing, samples, create_depth_texture);
--]]



GL_NV_conservative_raster_ok = gh_renderer.check_opengl_extension("GL_NV_conservative_raster")


-- GLSL shaders loading
--
tex_prog = gh_node.getid("tex_prog")
cr_prog = gh_node.getid("cr_prog")




gh_renderer.set_scissor_state(0) 



bias_xbits, bias_ybits, max_bias_bits = gh_renderer.conservative_rasterization_get_properties_nv()
print("conservative_rasterization_get_properties_nv()")
print("- bias_xbits = " .. bias_xbits)
print("- bias_ybits = " .. bias_ybits)
print("- max_bias_bits = " .. max_bias_bits)

xbits = 2
ybits = 2

show_conservative_raster = 1
render_target_scale = 20.0



