

kx_frame_begin(0.0, 0.0, 0.0)

kx_check_input()


local elapsed_time = kx_gettime()

local mx, my = kx_mouse_get_position()
my = winH - my
		
gh_camera.bind(camera_ortho)

gh_renderer.set_depth_test_state(0)

gh_gpu_program.bind(shadertoy_prog)
gh_gpu_program.uniform3f(shadertoy_prog, "iResolution", winW, winH, 0.0)
gh_gpu_program.uniform1f(shadertoy_prog, "iGlobalTime", elapsed_time)
gh_gpu_program.uniform1f(shadertoy_prog, "iTime", elapsed_time)
gh_gpu_program.uniform4f(shadertoy_prog, "iMouse", mx, my, 0, 0)


