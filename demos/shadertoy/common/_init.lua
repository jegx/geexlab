
local lib_dir = gh_utils.get_scripting_libs_dir() 		
local framework_dir = lib_dir .. "lua/framework_v1/"
dofile(framework_dir .. "kx.lua")


kx_init_begin(framework_dir)

kx_set_demo_caption("Shadertoy demo")






winW, winH = gh_window.getsize(0)
g_quad = gh_mesh.create_quad(winW, winH)


camera_ortho = kx_get_ortho_camera()

shadertoy_prog = gh_node.getid("shadertoy_prog")



kx_init_end()

