
local demo_dir = gh_utils.get_demo_dir()    
local lib_dir = gh_utils.get_lib_dir()     

dofile(lib_dir .. "lua/gx_cam_lib_v1.lua")
dofile(lib_dir .. "lua/libfont/libfont1.lua")   
dofile(lib_dir .. "lua/imgui.lua")    






random = function(a, b)
  if (a > b) then
    local c = b
    b = a
    a = c
  end
  local delta = b-a
  return (a + math.random()*delta)
end




mouse_get_position = function()
  local mx, my = gh_input.mouse_getpos()
  
  if (gh_utils.get_platform() == 2) then -- OSX     
    local w, h = gh_window.getsize(0)
    my = h - my
  end
    
  if (gh_utils.get_platform() == 4) then -- RPi
    local w, h = gh_window.getsize(0)
    mx = mx + w/2
    my = -(my - h/2) 
  end
  
  return mx, my
end    






winW, winH = gh_window.getsize(0)



is_gui_hovered = 0


is_windows = 0

if (gh_utils.get_platform() == 1) then -- return 1 if Windows, 2 if osx, 3 if linux, 4 if rpi and 5 if tinker board
  is_windows = 1
end





background_color = {r=0.4, g=0.4, b=0.4, a=1.0}




orbit_mode = 1
keyboard_speed = 10.0
camera_fov = 60.0
camera_lookat_x = 0
camera_lookat_y = 30
camera_lookat_z = 0

camera = gx_camera.create_perspective(60, 1, 0, 0, winW, winH, 0.1, 1000)
gh_camera.set_position(camera, 0, camera_lookat_y, 50)

if (orbit_mode == 1) then
  gx_camera.init_orientation(camera, camera_lookat_x, camera_lookat_y, camera_lookat_z, 30, 90)
  gx_camera.set_mode_orbit()
else
  gx_camera.set_mode_fly()
end

gx_camera.set_orbit_lookat(camera, camera_lookat_x, camera_lookat_y, camera_lookat_z)
gx_camera.set_keyboard_speed(keyboard_speed)
gh_camera.set_fov(camera, camera_fov)








phong_prog = gh_node.getid("phong_prog")
gh_gpu_program.uniform4f(phong_prog, "color", 1.0, 1.0, 1.0, 1.0)





ground = gh_mesh.create_plane(200, 200, 10, 10)



--flag_support = gh_mesh.create_box(1, 50, 1, 2, 2, 2)
--gh_object.setpos(flag_support, -20, 25, 0)

flag_support = gh_mesh.create_box(60, 1, 1, 2, 2, 2)
gh_object.setpos(flag_support, 0, 30, 0)



gizmo = gh_object.create()
gh_object.set_display_tripod_state(gizmo, 1)
gh_object.set_display_grid_state(gizmo, 1)
gh_object.set_grid_params(gizmo, 50.0, 50.0, 10, 10, 1, 1)







image_filename = ""
load_image_dnd = 0




local PF_U8_RGB = 1
local PF_U8_RGBA = 3
local PF_F32_RGBA = 6
local pixel_format = PF_U8_RGBA
local gen_mipmaps = 1
local compressed_texture = 0

--local filename = demo_dir .. "data/Ground_Dirt_1k_d.jpg"
local filename = demo_dir .. "data/Concrete_sidewalk_1k_d.jpg"
ground_tex = gh_texture.create_from_file_v6(filename, pixel_format, gen_mipmaps, compressed_texture)

filename = demo_dir .. "data/pexels-photo-289225.jpeg"
flag_tex = gh_texture.create_from_file_v6(filename, pixel_format, gen_mipmaps, compressed_texture)


local SAMPLER_FILTERING_NEAREST = 1
local SAMPLER_FILTERING_LINEAR = 2
local SAMPLER_FILTERING_TRILINEAR = 3
local SAMPLER_ADDRESSING_WRAP = 1
local SAMPLER_ADDRESSING_CLAMP_TO_EDGE = 2
local SAMPLER_ADDRESSING_MIRROR = 3
gh_texture.bind(ground_tex, 0)
gh_texture.set_sampler_params(ground_tex, SAMPLER_FILTERING_TRILINEAR, SAMPLER_ADDRESSING_WRAP, 16.0)
gh_texture.bind(0, 0)








_cloth_run_on_gpu = 0

px_scene = 0
px_cloth = 0
px_cloth2 = 0
flag_mesh = 0


physx_ok = gh_physx3.start()
if (physx_ok == 1) then
  gh_utils.trace("PhysX 3 started up ok.")
  
  
  local gpu_physx = gh_physx3.gpu_is_supported()
  --gpu_physx = 0
  if (gpu_physx == 1) then
    gh_utils.trace("PhysX 3 - GPU PhysX supported.")
    gh_utils.trace("PhysX 3 - GPU name:" .. gh_physx3.gpu_get_name())

    local mem_size = gh_physx3.gpu_get_total_memory_size_mb()
    gh_utils.trace("PhysX 3 - GPU total memory:" .. mem_size .. "MB")
    
    gh_utils.trace("PhysX 3 - Dedicated GPU:" .. gh_physx3.gpu_is_dedicated())
  else
    gh_utils.trace("PhysX 3 - GPU PhysX NOT supported, CPU PhysX only.")
  end

  
  
  
  local gravity = {x=0, y=-9.8, z=0}

  local bounce_threshold_velocity = 2.0
  local ccd = 0
  local enable_collision_reporting = 0
  local enable_stabilization = 1
  -- GPU PhysX  
  px_scene = gh_physx3.create_scene_broadphase_gpu(bounce_threshold_velocity, ccd, enable_collision_reporting, enable_stabilization)
  -- CPU PhysX  
  -- px_scene = gh_physx3.create_scene_broadphase_sap(bounce_threshold_velocity, ccd, enable_collision_reporting, enable_stabilization)


  gh_physx3.set_scene_gravity(px_scene, gravity.x, gravity.y, gravity.z)

  px_material_plane = gh_physx3.create_material(0.5, 0.5, 0.4)
  px_actor_plane = gh_physx3.create_actor_plane(px_scene, 0, 1, 0, 0, px_material_plane)


  
  cloth_vertex_density = 50
  local gpu_cloth = 1
  _cloth_run_on_gpu = gpu_cloth
  


  local pos = {x=0, y=30, z=0}
  local euler_angles = {x=90, y=0, z=0}
--  flag_mesh = gh_mesh.create_plane(40, 25, cloth_vertex_density, cloth_vertex_density)
  
  local separate_vertex_arrays = 1
  local vertex_alignment = 0
  local vertex_format = 0
  flag_mesh40x25 = gh_mesh.create_plane_v2(50, 30, cloth_vertex_density, cloth_vertex_density, separate_vertex_arrays, vertex_alignment, vertex_format)
    
  gh_object.setpos(flag_mesh40x25, pos.x, pos.y, pos.z)
  gh_object.set_euler_angles(flag_mesh40x25, euler_angles.x, euler_angles.y, euler_angles.z)

  --[[
  local num_vertices = gh_object.get_num_vertices(flag_mesh)
  local v = 0
  for v=0, num_vertices-1 do
    gh_mesh.set_vertex_position_w(flag_mesh, v, 10.8)
  end
  --]]
  
  gh_mesh.update_vertex_particle_from_position(flag_mesh40x25)
  gh_mesh.set_vertices_particle_w(flag_mesh40x25, 10.01)
  local MESH_PLANE_BORDER_TYPE_NEGX = 1
  local MESH_PLANE_BORDER_TYPE_POSX = 2
  local MESH_PLANE_BORDER_TYPE_NEGZ = 4
  local MESH_PLANE_BORDER_TYPE_POSZ = 8
  local MESH_PLANE_BORDER_TYPE_NEGY = 16
  local MESH_PLANE_BORDER_TYPE_POSY = 32
  local two_points = 1
  --gh_mesh.vertex_particle_attach_border(flag_mesh40x25, MESH_PLANE_BORDER_TYPE_NEGZ, two_points)
  gh_mesh.vertex_particle_attach_border(flag_mesh40x25, MESH_PLANE_BORDER_TYPE_NEGZ, 0)
  
  -- v = num_vertices/2
  -- gh_mesh.set_vertex_position_w(flag_mesh, v, 0.0) -- fixed vertex.
  
  px_cloth = gh_physx3.cloth_create_from_mesh(px_scene, flag_mesh40x25, gpu_cloth, pos.x, pos.y, pos.z, euler_angles.x, euler_angles.y, euler_angles.z, gravity.x, gravity.y, gravity.z)
  if (px_cloth > 0) then
    local update_positions = 1
    local update_normals = 1
    gh_physx3.cloth_update_mesh_vertex_data(px_cloth, flag_mesh40x25, update_positions, update_normals)
    --gh_physx3.cloth_set_solver_frequency(px_cloth, 120.0)
    --gh_physx3.cloth_set_gpu_state(px_cloth, 1)

    gh_physx3.cloth_set_external_acceleration(px_cloth, 10.0 + random(-5.0, 2.0), 2.0 + random(-2.0, 2.0), 6.0 + random(-4.0, 2.0))

  end










  pos.y = 30

  flag_mesh48x72 = gh_mesh.create_plane_v2(30, 40, cloth_vertex_density, cloth_vertex_density, separate_vertex_arrays, vertex_alignment, vertex_format)

  gh_object.setpos(flag_mesh48x72, pos.x, pos.y, pos.z)
  gh_object.set_euler_angles(flag_mesh48x72, euler_angles.x, euler_angles.y, euler_angles.z)

  gh_mesh.update_vertex_particle_from_position(flag_mesh48x72)
  gh_mesh.set_vertices_particle_w(flag_mesh48x72, 10.01)
  --local two_points = 1
  --gh_mesh.vertex_particle_attach_border(flag_mesh48x72, MESH_PLANE_BORDER_TYPE_NEGX, two_points)
  local two_points = 0
  gh_mesh.vertex_particle_attach_border(flag_mesh48x72, MESH_PLANE_BORDER_TYPE_NEGZ, two_points)
  
  -- v = num_vertices/2
  -- gh_mesh.set_vertex_position_w(flag_mesh, v, 0.0) -- fixed vertex.
  
  px_cloth2 = gh_physx3.cloth_create_from_mesh(px_scene, flag_mesh48x72, gpu_cloth, pos.x, pos.y, pos.z, euler_angles.x, euler_angles.y, euler_angles.z, gravity.x, gravity.y, gravity.z)
  if (px_cloth2 > 0) then
    local update_positions = 1
    local update_normals = 1
    gh_physx3.cloth_update_mesh_vertex_data(px_cloth2, flag_mesh48x72, update_positions, update_normals)
    --gh_physx3.cloth_set_solver_frequency(px_cloth2, 240.0)

    --gh_physx3.cloth_set_external_acceleration(px_cloth2, 4.0 + random(-2.0, 2.0), 2.0 + random(-2.0, 2.0), 2.0 + random(-4.0, 4.0))
    gh_physx3.cloth_set_external_acceleration(px_cloth2, 10.0 + random(-5.0, 2.0), 2.0 + random(-2.0, 2.0), 6.0 + random(-4.0, 2.0))
  end

  gh_physx3.scene_remove_actor(px_scene, px_cloth2)
  --gh_physx3.scene_remove_actor(px_scene, px_cloth)


  
  gh_utils.trace("PhysX 3 scene/materials/actors init ok.")
else  
  gh_utils.trace("PhysX 3 starting up failed.")
end  




gh_renderer.set_vsync(1)
gh_renderer.set_scissor_state(0)

last_time = gh_window.timer_get_seconds(0)

_wireframe = 0

_update_cloth_normals = 1
_update_cloth_normals_counter = 0
_run_sim_counter = 0

update_wind_force_time = 0

_keyboard_last_time = last_time


gl_renderer = gh_renderer.get_renderer_model()
gl_version = gh_renderer.get_api_version()

fps_time = 0
fps = 0
frames = 0

run_simulation = 1

show_info = 1
show_ground = 1

check_dnd_dst = 1 -- 1=flag, 0=ground

widescreen_flag = 1


