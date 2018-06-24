
local elapsed_time = gh_utils.get_elapsed_time()
local dt = elapsed_time - last_time
last_time = elapsed_time
    

gh_renderer.set_depth_test_state(1)


keyboard_speed = 2.0
gx_camera.set_keyboard_speed(keyboard_speed)


gx_camera.update(camera, dt)
gh_camera.bind(camera)


local camx, camy, camz = gh_camera.get_position(camera)


gh_renderer.clear_color_depth_buffers(0.2, 0.2, 0.2, 1.0, 1.0)





local mouse_x, mouse_y = gh_input.mouse_getpos() 
local platform_type = gh_utils.get_platform()
if (platform_type == 2) then -- OSX
  mouse_y = winH - mouse_y
end






gh_gpu_program.bind(light_prog)

local lx = 10.0 * math.sin(elapsed_time * 2.0)
local ly = 5.0
local lz = 10.0 * math.cos(elapsed_time * 2.0)
gh_gpu_program.uniform4f(light_prog, "light_position", lx, ly, lz, 1.0)
  
  
  
--gh_renderer.wireframe()
gh_renderer.enable_state("GL_CULL_FACE")

gh_object.set_position(mesh, 0, 1, 0)
gh_object.set_euler_angles(mesh, 0, 0, 0)
gh_object.render(mesh)

gh_renderer.disable_state("GL_CULL_FACE")
gh_renderer.solid()



gh_gpu_program.bind(color_prog)
gh_object.set_position(light_sphere, lx, ly, lz)
gh_object.render(light_sphere)
gh_object.render(grid)



    
gh_utils.font_render(font_a, 10, 20, 0.2, 1.0, 0.0, 1.0, string.format("GeeXLab - Heightmap normal"))
gh_utils.font_render(font_a, 10, 40, 1.0, 0.4, 0.4, 1.0, string.format("Plane - vertices:%d - faces:%d", num_vertices, num_faces))
gh_utils.font_render(font_a, 10, 60, 1.0, 0.4, 0.4, 1.0, string.format("Camera - <%.3f ; %.3f ; %.3f>", camx, camy, camz))






