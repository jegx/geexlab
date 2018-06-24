
local elapsed_time = gh_window.timer_get_seconds(0)
local dt = elapsed_time - last_time
last_time = elapsed_time

frames = frames+1
fps_time = fps_time + dt
if (fps_time >= 1.0) then
  fps_time = 0
  fps = frames
  frames = 0
end  



if (is_windows == 1) then
  gh_window.keyboard_update_buffer(0)
end








if (load_image_dnd == 1) then

  load_image_dnd = 0

  local PF_U8_RGB = 1
  local PF_U8_RGBA = 3
  local PF_F32_RGBA = 6
  local pixel_format = PF_U8_RGBA
  local gen_mipmaps = 1
  local compressed_texture = 0
  local free_cpu_memory = 1
  local upload_to_gpu = 1

  -- try to load the image with ImageMagick plugin
  local tex = gh_imagemagick.texture_create_from_file(image_filename, pixel_format, gen_mipmaps, free_cpu_memory, upload_to_gpu)
  if (tex == 0) then
    -- try with built-in image loader
    tex = gh_texture.create_from_file_v6(image_filename, pixel_format, gen_mipmaps, compressed_texture)
  end

  if (tex > 0) then

    if (check_dnd_dst == 1) then -- flag texture

      -- We change the cloth depending on the size of the texture
      -- but only for the flag texture.
      --
      local texw, texh = gh_texture.get_size(tex)

      print(string.format("image size: %dx%d", texw, texh))

      if (texw > texh) then
        widescreen_flag = 1

        gh_physx3.scene_remove_actor(px_scene, px_cloth2)
        gh_physx3.scene_add_actor(px_scene, px_cloth)


      else
        widescreen_flag = 0

        gh_physx3.scene_remove_actor(px_scene, px_cloth)
        gh_physx3.scene_add_actor(px_scene, px_cloth2)

      end
    end



    if (check_dnd_dst == 0) then
      gh_node.kill(ground_tex)
      ground_tex = tex
    else
      gh_node.kill(flag_tex)
      flag_tex = tex
    end
  end
end















--[[
local KC_G = 34
local KC_SPACE = 57
if (px_cloth > 0) then
  local dt = elapsed_time - _keyboard_last_time
  if (dt > 0.5) then
    if (gh_input.keyboard_is_key_down(KC_SPACE) == 1) then
      _keyboard_last_time = elapsed_time
      if (_wireframe == 0) then
        _wireframe = 1
      else
        _wireframe = 0
      end
    end
    
    if (gh_input.keyboard_is_key_down(KC_G) == 1) then
      _keyboard_last_time = elapsed_time
      if (_cloth_run_on_gpu == 0) then
        _cloth_run_on_gpu = 1
      else
        _cloth_run_on_gpu = 0
      end
      gh_physx3.cloth_set_gpu_state(px_cloth, _cloth_run_on_gpu)
    end
  end
end
--]]



local pxcloth = px_cloth
local meshflag = flag_mesh40x25
if (widescreen_flag == 0) then
  pxcloth = px_cloth2
  meshflag = flag_mesh48x72
end




local run_sim = 0
if (run_simulation == 1) then

  if ((elapsed_time - update_wind_force_time) > 1.0) then
    update_wind_force_time = elapsed_time
    gh_physx3.cloth_set_external_acceleration(pxcloth, 3.0 + random(-2.0, 2.0), 2.0 + random(-2.0, 2.0), 2.0 + random(-2.0, 2.0))
  end

  -- gh_physx3.run_simulation(px_scene, 0.002, 0.01)
  --run_sim = gh_physx3.run_simulation(px_scene, 1.0/240.0, 1.0/60.0)
  run_sim = gh_physx3.run_simulation(px_scene, 1.0/60.0, 1.0/60.0)

  _update_cloth_normals = 0
  _run_sim_counter = _run_sim_counter + 1
  if (run_sim == 1) then
    _update_cloth_normals = 1
    _run_sim_counter = 0
  end

end






















if (is_gui_hovered == 0) then
  gx_camera.update(camera, dt)
end  
gh_camera.bind(camera)

gh_renderer.set_depth_test_state(1)
gh_renderer.clear_color_depth_buffers(background_color.r, background_color.g, background_color.b, 1.0, 1.0)
















local p = phong_prog
gh_gpu_program.bind(p)
gh_gpu_program.uniform4f(p, "light_position", 20.0, 100.0, 100.0, 1.0)
gh_gpu_program.uniform4f(p, "light_diffuse", 1.0, 1.0, 0.95, 1.0)
gh_gpu_program.uniform4f(p, "light_specular", 0.9, 0.9, 0.9, 1.0)
gh_gpu_program.uniform4f(p, "material_diffuse", 0.8, 0.8, 0.8, 1.0)
gh_gpu_program.uniform4f(p, "material_specular", 0.6, 0.6, 0.6, 1.0)
gh_gpu_program.uniform1f(p, "material_shininess", 60.0)



if (show_ground == 1) then
  gh_gpu_program.uniform4f(p, "uv_tiling", 4.0, 4.0, 1.0, 1.0)
  gh_gpu_program.uniform1i(p, "use_texture", 1)
  gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "material_specular", 0.1, 0.1, 0.1, 1.0)
  gh_gpu_program.uniform1f(p, "material_shininess", 2.0)
  gh_texture.bind(ground_tex, 0)
  gh_object.render(ground)
end


gh_gpu_program.uniform1i(p, "use_texture", 0)
gh_gpu_program.uniform4f(p, "color", 0.5, 0.5, 0.6, 1.0)
gh_gpu_program.uniform4f(p, "material_specular", 0.8, 0.8, 0.9, 1.0)
gh_gpu_program.uniform1f(p, "material_shininess", 80.0)

local horizontal_support_y = 45.0  -- 30 + 30/2
if (widescreen_flag == 0) then
  horizontal_support_y = 50 -- 30 + 40/2
end


gh_object.set_position(flag_support, 0, horizontal_support_y, 0)
gh_object.set_euler_angles(flag_support, 0, 0, 0)
gh_object.render(flag_support)

gh_object.set_position(flag_support, -30, 30, 0)
gh_object.set_euler_angles(flag_support, 0, 0, 90)
gh_object.render(flag_support)

gh_object.set_position(flag_support, 30, 30, 0)
gh_object.set_euler_angles(flag_support, 0, 0, 90)
gh_object.render(flag_support)



if (_wireframe == 1) then
  gh_renderer.wireframe()
end




  --gh_physx3.cloth_set_solver_frequency(cloth, 120.0)


if (pxcloth > 0) then
  local update_positions = 1
  local update_normals = 1
  if (run_sim == 1) then
    gh_physx3.cloth_update_mesh_vertex_data(pxcloth, meshflag, update_positions, update_normals)
  end

  gh_gpu_program.uniform1i(p, "use_texture", 1)
  gh_gpu_program.uniform4f(p, "color", 1.0, 1.0, 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "uv_tiling", 1.0, 1.0, 1.0, 1.0)
  gh_gpu_program.uniform4f(p, "material_specular", 0.6, 0.6, 0.6, 1.0)
  gh_gpu_program.uniform1f(p, "material_shininess", 60.0)
  gh_texture.bind(flag_tex, 0)
  gh_object.render(meshflag)
end



if (_wireframe == 1) then
  gh_renderer.solid()
end  




gh_renderer.set_depth_test_state(0)




if (show_info == 1) then

  libfont_clear()

  local y_offset = 40

  libfont_print(20, y_offset, 1, 0.5, 0, 1, ">> PhysX 3 Image Viewer <<")
  y_offset = y_offset + 20

  if (is_windows == 1) then
    y_offset = y_offset + 20
    libfont_print(20, y_offset, 1, 1.0, 1, 1, "Drag and drop an image...")
    y_offset = y_offset + 20
  end

  y_offset = y_offset + 20
  libfont_print(20, y_offset, 1, 1, 0, 1, "FPS: " .. fps)
  y_offset = y_offset + 20


  y_offset = y_offset + 20
  libfont_print(20, y_offset, 1, 1, 0, 1, "PhysX GPU")
  y_offset = y_offset + 20
  libfont_print(20, y_offset, 1, 1, 1, 1, "> " .. gh_physx3.gpu_get_name())

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
end




--[[
local y_offset = 20

gh_utils.tripod_visualizer_camera_render(camera, winW-100, 20, 100, 100)
    
gh_utils.font_render(font_a, 10, y_offset, 0.2, 1.0, 0.0, 1.0, "PhysX 3.3 cloth demo")
y_offset = y_offset + 20
gh_utils.font_render(font_a, 10, y_offset, 0.7, 0.7, 0.7, 1.0, "Controls - [SPACE]: toogle wireframe - [G]:toogle GPU PhysX")
y_offset = y_offset + 20
if (px_cloth > 0) then
  local on_gpu = gh_physx3.cloth_is_running_on_gpu(px_cloth)
  gh_utils.font_render(font_a, 10, y_offset, 1.0, 1.0, 0.0, 1.0, "PhysX GPU: " .. gh_physx3.gpu_get_name())
  y_offset = y_offset + 20
  gh_utils.font_render(font_a, 10, y_offset, 1.0, 1.0, 0.0, 1.0, "Cloth running on GPU: " .. on_gpu)
  y_offset = y_offset + 20
  gh_utils.font_render(font_a, 10, y_offset, 1.0, 1.0, 0.0, 1.0, string.format("Cloth vertex density: %dx%d", cloth_vertex_density, cloth_vertex_density))
  y_offset = y_offset + 20
  --gh_utils.font_render(font_a, 10, y_offset, 1.0, 1.0, 0.0, 1.0, string.format("_run_sim_counter: %d", _run_sim_counter))
  --y_offset = y_offset + 20
end
--]]



















local mouse_x, mouse_y = mouse_get_position()

imgui_frame_begin_v2(mouse_x, mouse_y)


--gh_imgui.set_color(IMGUI_TITLE_BG_COLOR, 0.4, 0.4, 0.4, 0.90)

gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.1, 0.1, 0.1, 0.6)


local pos_size_flag_always = 1 -- Always set the pos and/or size
local pos_size_flag_once = 2 -- Set the pos and/or size once per runtime session (only the first call with succeed)
local pos_size_flag_first_use_ever = 4  -- Set the pos and/or size if the window has no saved data (if doesn't exist in the .ini file)
local pos_size_flag_appearing = 8  -- Set the pos and/or size if the window is appearing after being hidden/inactive (or the first time)

local window_flags = 0 -- ImGuiWindowFlags_NoResize


is_gui_hovered = 0


local is_open = imgui_window_begin_v1("Control panel", 300, 350, 10, 300)
--local is_open = imgui_window_begin_v1("Control panel", 360, 560, 20, 20)
if (is_open == 1) then

  local window_w = gh_imgui.get_content_region_available_width()

  local widget_width = window_w * 1.0
  

  gh_imgui.text("run_simulation: " .. run_simulation)


  imgui_vertical_space()
 
  
  imgui_vertical_space()
  imgui_vertical_space()
  if (run_simulation == 1) then
    if (gh_imgui.button("Pause simulation", 150, 20) == 1) then
      run_simulation = 0
    end
  else
    if (gh_imgui.button("Run simulation", 150, 20) == 1) then
      run_simulation = 1
    end
  end

  imgui_vertical_space()
  imgui_vertical_space()
  if (show_info == 1) then
    if (gh_imgui.button("Hide info", 150, 20) == 1) then
      show_info = 0
    end
  else
    if (gh_imgui.button("Show info", 150, 20) == 1) then
      show_info = 1
    end
  end

  imgui_vertical_space()
  imgui_vertical_space()
  if (show_ground == 1) then
    if (gh_imgui.button("Hide the ground", 150, 20) == 1) then
      show_ground = 0
    end
  else
    if (gh_imgui.button("Show the ground", 150, 20) == 1) then
      show_ground = 1
    end
  end




  imgui_vertical_space()
  imgui_vertical_space()
  if (_wireframe == 1) then
    if (gh_imgui.button("Solid/Fill", 150, 20) == 1) then
      _wireframe = 0
    end
  else
    if (gh_imgui.button("Wireframe", 150, 20) == 1) then
      _wireframe = 1
    end
  end




  imgui_vertical_space()
  imgui_vertical_space()
  if (orbit_mode == 1) then
    if (gh_imgui.button("Look free", 150, 20) == 1) then
      orbit_mode = 0
      gx_camera.set_mode_fly()
      keyboard_speed = 40
      gx_camera.set_keyboard_speed(keyboard_speed)
    end
  else
    if (gh_imgui.button("Orbit", 150, 20) == 1) then
      orbit_mode = 1
      gx_camera.set_mode_orbit()
      keyboard_speed = 10
      gx_camera.set_keyboard_speed(keyboard_speed)
    end
  end



  imgui_vertical_space()
  imgui_vertical_space()
  if (check_dnd_dst == 1) then
    gh_imgui.text("Drag and Drop destination: flag")
  else
    gh_imgui.text("Drag and Drop destination: ground")
  end
  check_dnd_dst = gh_imgui.checkbox("destination: flag", check_dnd_dst)





  

  imgui_vertical_space()


  gh_imgui.push_item_width(widget_width)
  

  
  
  imgui_vertical_space()
  imgui_vertical_space()

  local dummy_a = 1.0
  
  gh_imgui.text("Background color")
  background_color.r, background_color.g, background_color.b, dummy_a = gh_imgui.color_edit_rgba("##colorpicker-background", background_color.r, background_color.g, background_color.b, dummy_a)
  
  

  gh_imgui.pop_item_width()
  
  
  is_gui_hovered = 0
  if ((gh_imgui.is_window_hovered() == 1) or (gh_imgui.is_any_item_hovered() == 1)) then
    is_gui_hovered = 1
  end
  


end 

imgui_window_end()

imgui_frame_end()
