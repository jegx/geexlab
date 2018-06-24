
local elapsed_time = gh_utils.get_elapsed_time()
local dt = gh_utils.get_time_step()

frames = frames+1
fps_time = fps_time + dt
if (fps_time >= 1.0) then
  fps_time = 0
  fps = frames
  frames = 0
end  


if (win_hovered == 0) then
  gx_camera.update(camera, dt)
end  
gh_camera.bind(camera)



gh_renderer.set_depth_test_state(1)


gh_renderer.clear_color_depth_buffers(0.3, 0.3, 0.3, 1, 1.0)



gh_gpu_program.bind(wireframe_prog)
--gh_gpu_program.uniform3f(wireframe_prog, "WIRE_COL", 0.0, 0.0, 0.0, 1.0)
--gh_gpu_program.uniform3f(wireframe_prog, "FILL_COL", 1.0, 0.5, 0.0, 1.0)
--gh_gpu_program.uniform2f(wireframe_prog, "WIN_SCALE", 20, 20)



gh_gpu_program.uniform3f(wireframe_prog, "WIRE_COL", wire_color.r, wire_color.g, wire_color.b, 1.0)
gh_gpu_program.uniform3f(wireframe_prog, "FILL_COL", fill_color.r, fill_color.g, fill_color.b, 1.0)
gh_gpu_program.uniform2f(wireframe_prog, "WIN_SCALE", 25, 25)



--gh_texture.bind(tex0, 0)
gh_object.render(sphere)
gh_object.render(torus)







--gx_camera.draw_ref_grid(20, 20, 20, 20)
gx_camera.draw_tripod(camera)






---[[
libfont_clear()

local y_offset = 40

libfont_print(20, y_offset, 1, 0.5, 0, 1, "Wireframe shader")
y_offset = y_offset + 20

y_offset = y_offset + 20
libfont_print(20, y_offset, 1, 1, 0, 1, "FPS: " .. fps)
y_offset = y_offset + 20

y_offset = y_offset + 20
libfont_print(20, y_offset, 1, 1, 0, 1, "GL_RENDERER")
y_offset = y_offset + 20
libfont_print(20, y_offset, 1, 1, 1, 1, "> " .. gl_renderer)
y_offset = y_offset + 20

libfont_print(20, y_offset, 1, 1, 0, 1, "GL_VERSION")
y_offset = y_offset + 20
libfont_print(20, y_offset, 1, 1, 1, 1, "> " .. gl_version)
y_offset = y_offset + 20


libfont_render()
--]]











  imgui_frame_begin()

  --gh_imgui.set_color(IMGUI_TITLE_BG_COLOR, 0.4, 0.4, 0.4, 0.90)

  gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.1, 0.1, 0.1, 0.6)


  local pos_size_flag_always = 1 -- Always set the pos and/or size
  local pos_size_flag_once = 2 -- Set the pos and/or size once per runtime session (only the first call with succeed)
  local pos_size_flag_first_use_ever = 4  -- Set the pos and/or size if the window has no saved data (if doesn't exist in the .ini file)
  local pos_size_flag_appearing = 8  -- Set the pos and/or size if the window is appearing after being hidden/inactive (or the first time)

  local window_flags = ImGuiWindowFlags_NoResize

  local is_open = gh_imgui.window_begin("Control panel", 300, 200, 10, 200, window_flags, pos_size_flag_once, pos_size_flag_once)
  --local is_open = imgui_window_begin_v1("Control panel", 360, 560, 20, 20)
  if (is_open == 1) then
  
    

    win_hovered = gh_imgui.is_window_hovered()
            
  
    local window_w = gh_imgui.get_content_region_available_width()

    local widget_width = window_w * 1.0
    
    
    gh_imgui.text("Press [ESC] to quit the demo")
    
    ---[[

    imgui_vertical_space()
    imgui_vertical_space()


    gh_imgui.push_item_width(widget_width)

    --[[
    gh_imgui.text("Simulation speed factor")
    local min_value = 1.0
    local max_value = 200.0
    local power = 1.0
    g_simulation_speed_factor = gh_imgui.slider_1f("##simspeed", g_simulation_speed_factor,   min_value, max_value,   power)

    imgui_vertical_space()
    imgui_vertical_space()
    --]]

    
    imgui_vertical_space()
    imgui_vertical_space()

    local dummy_a = 1.0
    
    gh_imgui.text("Wire color")
    wire_color.r, wire_color.g, wire_color.b, dummy_a = gh_imgui.color_edit_rgba("##colorpicker-wire", wire_color.r, wire_color.g, wire_color.b, dummy_a)

    imgui_vertical_space()
    imgui_vertical_space()

    gh_imgui.text("Fill color")
    fill_color.r, fill_color.g, fill_color.b, dummy_a = gh_imgui.color_edit_rgba("##colorpicker-fill", fill_color.r, fill_color.g, fill_color.b, dummy_a)
    

    gh_imgui.pop_item_width()
    --]]


  end 

  imgui_window_end()

  imgui_frame_end()
  --
  -- ImGui end ---------------------------------------------------------------
  ----------------------------------------------------------------------------
  --]]
