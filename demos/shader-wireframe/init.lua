
local demo_dir = gh_utils.get_demo_dir()
    
local lib_dir = gh_utils.get_scripting_libs_dir() 		
dofile(lib_dir .. "lua/gx_cam_lib_v1.lua")
dofile(lib_dir .. "lua/libfont/libfont1.lua")   
dofile(lib_dir .. "lua/imgui.lua")    


winW, winH = gh_window.getsize(0)




--[[
local aspect = winW / winH
camera = gh_camera.create_persp(60, aspect, 0.1, 1000.0)
gh_camera.set_viewport(camera, 0, 0, winW, winH)
gh_camera.set_position(camera, 0, 0.2, 0.4)
gh_camera.set_lookat(camera, 0, 0, 0, 1)
gh_camera.setupvec(camera, 0, 1, 0, 0)
--]]





orbit_mode = 1
keyboard_speed = 10.0
camera_fov = 60.0
camera_lookat_x = 0
camera_lookat_y = 0
camera_lookat_z = 0

camera = gx_camera.create_perspective(60, 1, 0, 0, winW, winH, 1, 1000)
gh_camera.set_position(camera, 0, 0, 15)
gx_camera.init_orientation(camera, 0, 0, 0, 30, 90)

if (orbit_mode == 1) then
  gx_camera.set_mode_orbit()
else
  gx_camera.set_mode_fly()
end

gx_camera.set_orbit_lookat(camera, camera_lookat_x, camera_lookat_y, camera_lookat_z)
gx_camera.set_keyboard_speed(keyboard_speed)
gh_camera.set_fov(camera, camera_fov)









wire_color = {r=1.0, g=1.0, b=1.0, a=1.0}
fill_color = {r=1.0, g=0.5, b=0.0, a=1.0}


wireframe_prog = gh_node.getid("wireframe_prog")


win_hovered = 0





---[[
local radius = 8.0
local section_radius = 1.0
local subdivisions = 20
torus = gh_mesh.create_torus(radius, section_radius, subdivisions)
gh_object.set_position(torus, 0, 0, 0)
--]]


local radius = 5
local subdivisions = 30
sphere = gh_mesh.create_sphere(radius, subdivisions, subdivisions)
gh_object.set_position(sphere, 0, 0, 0)
gh_object.set_euler_angles(sphere, 90, 0, 0)








gh_renderer.set_vsync(0)

last_time = gh_utils.get_elapsed_time()


gl_renderer = gh_renderer.get_renderer_model()
gl_version = gh_renderer.get_api_version()


fps_time = 0
fps = 0
frames = 0

