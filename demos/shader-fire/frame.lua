
local elapsed_time = gh_utils.get_elapsed_time()

gh_camera.bind(camera_ortho)
gh_renderer.clear_color_depth_buffers(0.0, 0.0, 0.0, 1.0, 1.0)


local BLEND_FACTOR_ZERO = 0
local BLEND_FACTOR_ONE = 1
local BLEND_FACTOR_SRC_ALPHA = 2
local BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 3
local BLEND_FACTOR_ONE_MINUS_DST_COLOR = 4
local BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 5
local BLEND_FACTOR_DST_COLOR = 6
local BLEND_FACTOR_DST_ALPHA = 7
local BLEND_FACTOR_SRC_COLOR = 8
local BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 9

gh_renderer.set_blending_state(1)
gh_renderer.set_blending_factors(BLEND_FACTOR_SRC_ALPHA, BLEND_FACTOR_ONE)


gh_texture.bind(tex_noise, 0)
gh_texture.bind(tex_gradient, 1)
gh_texture.bind(tex_gradient_color, 2)
gh_texture.bind(tex_distortion, 3)
gh_texture.bind(tex_color, 4)
gh_gpu_program.bind(texture_prog)
gh_gpu_program.uniform1f(texture_prog, "time", elapsed_time)
gh_gpu_program.uniform1f(texture_prog, "speed", 0.25)
gh_gpu_program.uniform1f(texture_prog, "alpha_threshold", 0.4)
gh_object.render(quad)


gh_renderer.set_blending_state(0)

