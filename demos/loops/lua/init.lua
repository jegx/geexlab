
APP_NAME = "Loops"
--APP_VERSION = "0.1.0"


local demo_dir = gh_utils.get_demo_dir()     

local lib_dir = gh_utils.get_scripting_libs_dir()     
dofile(lib_dir .. "lua/gx_cam_lib_v1.lua")
dofile(lib_dir .. "lua/imgui.lua")   



-- Utils - hsl_to_rgb()
dofile(demo_dir .. "lua/utils.lua")   




winW, winH = gh_window.getsize(0)


is_rpi = 0
if (gh_utils.get_platform() == 4) then -- return 1 if Windows, 2 if osx, 3 if linux, 4 if rpi and 5 if tinker board
  is_rpi = 1
end





---------------------------------------------------------------------------------------------
-- A 3D Orbit Mode camera managed by the Lua gx_camera library.
--
keyboard_speed = 4.0
camera_fov = 60.0
camera_lookat_x = 0
camera_lookat_y = 0
camera_lookat_z = 0
camera_znear = 0.1
camera_zfar = 1000.0

camera_persp = gx_camera.create_perspective(camera_fov, 1, 0, 0, winW, winH, camera_znear, camera_zfar)
gh_camera.set_position(camera_persp, 0, 0, 15.0)
gx_camera.init_orientation(camera_persp, camera_lookat_x, camera_lookat_y, camera_lookat_z, 2, 90)

gx_camera.set_mode_orbit()

camera = camera_persp





---------------------------------------------------------------------------------------------
-- An ortho cam for all non-3D objects.
--
camera_ortho = gh_camera.create_ortho(-winW/2, winW/2, -winH/2, winH/2, 1.0, 10.0)
gh_camera.set_viewport(camera_ortho, 0, 0, winW, winH)
gh_camera.set_position(camera_ortho, 0, 0, 4)



--------------------------------------------------------------------------------------------
-- The fullscreen quad for the background
--
fullscreen_quad = gh_mesh.create_quad(winW, winH)

bkg_color_top = {r=125/255, g=152/255, b=196/255, a=1}
bkg_color_bottom = {r=35/255, g=35/255, b=30/255, a=1}

gh_mesh.set_vertex_color(fullscreen_quad, 0, bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a) --bottom-left
gh_mesh.set_vertex_color(fullscreen_quad, 1, bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a) -- top-left
gh_mesh.set_vertex_color(fullscreen_quad, 2, bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a) --top-right
gh_mesh.set_vertex_color(fullscreen_quad, 3, bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a) --bottom-right








--------------------------------------------------------------------------------------------
-- The GLSL shaders
--
lighting_prog = gh_node.getid("lighting_prog")
color_prog = gh_node.getid("color_prog")









-------------------------------------------------------------------------------
-- The loop effect.
--
--dofile(demo_dir .. "loops/loop_104.lua")   
--dofile(demo_dir .. "loops/loop_099.lua")   

loop_init()







----------------------------------------------------------------------------------
-- A texture to enhance the cube rendering
--
local demo_dir = gh_utils.get_demo_dir()
local filename = demo_dir .. "assets/textures/white_black_border.jpg"
local PF_U8_RGB = 1
local PF_U8_RGBA = 3
local PF_F32_RGBA = 6
local pixel_format = PF_U8_RGBA
local gen_mipmaps = 1
local compressed_texture = 0
tex0 = gh_texture.create_from_file_v6(filename, pixel_format, gen_mipmaps, compressed_texture)





----------------------------------------------------------------------------------
-- The reference grid
--
grid_size = { x=50.0, y=50.0}

grid = gh_utils.grid_create()
gh_utils.grid_set_geometry_params(grid, grid_size.x, grid_size.y, 20, 20)
gh_utils.grid_set_lines_color(grid, 0.7, 0.7, 0.7, 1.0)
gh_utils.grid_set_main_lines_color(grid, 1.0, 1.0, 0.0, 1.0)
gh_utils.grid_set_main_x_axis_color(grid, 1.0, 0.0, 0.0, 1.0)
gh_utils.grid_set_main_z_axis_color(grid, 0.0, 0.0, 1.0, 1.0)
local display_main_lines = 1
local display_lines = 1
gh_utils.grid_set_display_lines_options(grid, display_main_lines, display_lines)





----------------------------------------------------------------------------------
-- Some render states and global variables
--

gh_renderer.set_vsync(1)
gh_renderer.set_scissor_state(0)


last_time = gh_utils.get_elapsed_time()


gl_renderer = gh_renderer.get_renderer_model()
gl_version = gh_renderer.get_api_version()


fps_time = 0
fps = 0
frames = 0


show_ref_grid = 1
if (is_rpi == 1) then
  show_ref_grid = 0 -- The ref grid is too slow on the RPi
end

show_light_sphere = 0

wireframe = 0




-- Helper object to display the position of lights.
light_sphere = gh_utils.sphere_create(0.25, 10, 1, 1, 1, 1)







--------------------------------------------------------------------------------------
-- ImGui functions
--------------------------------------------------------------------------------------

gh_imgui.init()

mouse_x , mouse_y = gh_input.mouse_get_position()

imgui_window_hovered = 0


--gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.1, 0.1, 0.1, 0.6)
gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.8, 0.8, 0.8, 0.4)
gh_imgui.set_color(IMGUI_RESIZE_GRIP_COLOR, 0.1, 0.1, 0.1, 0.0)
gh_imgui.set_color(IMGUI_RESIZE_GRIP_ACTIVE_COLOR, 0.1, 0.1, 0.1, 0.0)

gh_imgui.set_color(IMGUI_TITLE_BG_COLOR, 0.6, 0.3, 0.1, 1.0)
gh_imgui.set_color(IMGUI_TITLE_BG_ACTIVE_COLOR, 0.8, 0.4, 0.2, 1.0)

gh_imgui.set_color(IMGUI_CLOSE_BUTTON_COLOR, 0.4, 0.4, 0.4, 1.0)
gh_imgui.set_color(IMGUI_CLOSE_BUTTON_HOVERED_COLOR, 0.6, 0.6, 0.6, 1.0)
gh_imgui.set_color(IMGUI_CLOSE_BUTTON_ACTIVE_COLOR, 0.8, 0.8, 0.8, 1.0)


gh_imgui.set_color(IMGUI_FRAME_BG_COLOR, 0.5, 0.5, 0.5, 1.0)
gh_imgui.set_color(IMGUI_FRAME_BG_HOVERED_COLOR, 0.6, 0.6, 0.6, 1.0)
gh_imgui.set_color(IMGUI_FRAME_BG_ACTIVE_COLOR, 0.4, 0.6, 0.4, 1.0)

gh_imgui.set_color(IMGUI_BORDER_COLOR, 0.3, 0.3, 0.3, 1.0)

gh_imgui.set_color(IMGUI_POPUP_BG_COLOR, 0.7, 0.7, 0.7, 1.0)

gh_imgui.set_color(IMGUI_CHECK_MARK_COLOR, 0.0, 0.0, 0.0, 1.0)

gh_imgui.set_color(IMGUI_SCROLLBAR_BG_COLOR, 0.7, 0.7, 0.7, 1.0)
gh_imgui.set_color(IMGUI_SCROLLBAR_GRAB_COLOR, 0.5, 0.5, 0.5, 1.0)
gh_imgui.set_color(IMGUI_SCROLLBAR_GRAB_HOVERED_COLOR, 0.5, 0.5, 0.4, 1.0)

gh_imgui.set_color(IMGUI_SEPARATOR_COLOR, 0.6, 0.6, 0.6, 0.5)

gh_imgui.set_color(IMGUI_COLOR_BUTTON, 0.2, 0.1, 0.1, 1.0)
gh_imgui.set_color(IMGUI_COLOR_BUTTON_HOVERED, 0.9, 0.9, 0.3, 1.0)


gh_imgui.set_color(IMGUI_TEXT_COLOR, 1.0, 1.0, 1.0, 1.0)



function imgui_begin(win_width, win_height)

  local LEFT_BUTTON = 1
  local mouse_left_button = gh_input.mouse_get_button_state(LEFT_BUTTON) 
  local RIGHT_BUTTON = 2
  local mouse_right_button = gh_input.mouse_get_button_state(RIGHT_BUTTON) 
  mouse_x, mouse_y = gh_input.mouse_get_position()


  gh_imgui.frame_begin(winW, winH, mouse_x, mouse_y, mouse_left_button, mouse_right_button)

  local window_default = 0
  local window_no_resize = 2
  local window_no_move = 4
  local window_no_collapse = 32
  local window_show_border = 128
  local window_no_save_settings = 256
  local pos_size_flag_always = 1 -- Always set the pos and/or size
  local pos_size_flag_once = 2 -- Set the pos and/or size once per runtime session (only the first call with succeed)
  local pos_size_flag_first_use_ever = 4  -- Set the pos and/or size if the window has no saved data (if doesn't exist in the .ini file)
  local pos_size_flag_appearing = 8  -- Set the pos and/or size if the window is appearing after being hidden/inactive (or the first time)

  imgui_window_hovered = 0

  local window_flags = window_no_save_settings | window_no_resize

  local is_open = gh_imgui.window_begin(APP_NAME .. " - Control Panel", win_width, win_height, 0, 0, window_flags, pos_size_flag_always, pos_size_flag_always)

  if ((is_open == 1) and ((gh_imgui.is_window_hovered() == 1) or (gh_imgui.is_any_item_hovered() == 1))) then
    imgui_window_hovered = 1
  end 

  return is_open
end  


function imgui_end()

  gh_imgui.window_end()
  gh_imgui.frame_end()
end  




