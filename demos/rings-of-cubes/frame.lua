
local elapsed_time = gh_utils.get_elapsed_time()
local dt = gh_utils.get_time_step()

frames = frames+1
fps_time = fps_time + dt
if (fps_time >= 1.0) then
  fps_time = 0
  fps = frames
  frames = 0
end  







---------------------------------------------------------------------------------
-- Background
---------------------------------------------------------------------------------

gh_renderer.set_depth_test_state(0)

gh_camera.bind(camera_ortho)
gh_renderer.clear_color_depth_buffers(0, 0, 0, 0, 1.0)

gh_renderer.back_face_culling(0)


gh_gpu_program.bind(color_prog)

gh_mesh.set_vertex_color(fullscreen_quad, 0, bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a) --bottom-left
gh_mesh.set_vertex_color(fullscreen_quad, 1, bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a) -- top-left
gh_mesh.set_vertex_color(fullscreen_quad, 2, bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a) --top-right
gh_mesh.set_vertex_color(fullscreen_quad, 3, bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a) --bottom-right

gh_object.render(fullscreen_quad)
















---------------------------------------------------------------------------------
-- Main rendering
---------------------------------------------------------------------------------

gh_renderer.set_depth_test_state(1)



---------------------------------------------
-- Apply 3D camera settings
--
if (imgui_window_hovered == 0) then
  gh_camera.set_fov(camera, camera_fov)
  gx_camera.set_keyboard_speed(keyboard_speed)
  gx_camera.update(camera, dt)
end  
gh_camera.bind(camera)








-- The lighting shader ------------------------------
--
local prog = lighting_prog
gh_gpu_program.bind(prog)
gh_gpu_program.uniform1i(prog, "tex0", 0)


local cx, cy, cz = gh_camera.get_position(camera)
--gh_gpu_program.uniform4f(prog, "light_position0", cx, cy, cz, 1.0)


--local light0_pos = {x=15.0, y=1.0, z=1.0}
--local light1_pos = {x=-15.0, y=1.0, z=10.0}
local light0_pos = {x=8.0, y=4.0, z=8.0}
local light1_pos = {x=-8.0, y=11.0, z=-1.0}


gh_gpu_program.uniform4f(prog, "light_ambient", 0.2, 0.2, 0.2, 1.0)
gh_gpu_program.uniform4f(prog, "light_specular", 0.6, 0.6, 0.6, 1.0)

gh_gpu_program.uniform4f(prog, "light0_position", light0_pos.x, light0_pos.y, light0_pos.z, 1.0)
gh_gpu_program.uniform4f(prog, "light0_diffuse", 1.0, 1.0, 1.0, 1.0)

gh_gpu_program.uniform4f(prog, "light1_position", light1_pos.x, light1_pos.y, light1_pos.z, 1.0)
gh_gpu_program.uniform4f(prog, "light1_diffuse", 1.0, 1.0, 1.0, 1.0)

gh_gpu_program.uniform4f(prog, "uv_tiling", 1.0, 1.0, 0.0, 1.0)


gh_gpu_program.uniform4f(prog, "material_diffuse", 1.0, 1.0, 1.0, 1.0)
gh_gpu_program.uniform4f(prog, "material_ambient", 1.0, 1.0, 1.0, 1.0)
gh_gpu_program.uniform4f(prog, "material_specular", 0.1, 0.1, 0.1, 1.0)
gh_gpu_program.uniform1f(prog, "material_shininess", 24.0)







gh_renderer.back_face_culling(1)

if (tex0 > 0) then
  gh_gpu_program.uniform1i(prog, "tex0", 0)
  gh_texture.bind(tex0, 0)
end


if (wireframe == 1) then
  gh_renderer.wireframe()
end



-- The RINGS ------------------------------------------
-- Thanks to the hierarchy that allows to group objects together, we can easily rotate
-- a ring made up of several cubes. And several rings need to be rotated...
--
--
local ang_step = TAU / num_rings 

local time = elapsed_time

ring_radius = 4.0

for i=0, num_rings-1 do

  local pivot = pivots[i+1]
  local ring = rings[i+1]

  local ang = i * ang_step

  local px = ring_radius * math.cos(ang) 
  local py = ring_radius * math.sin(ang) 
  local pz = 0 

  
  local yaw = ang + PI/2.0 + 0.2
  local ang_deg = yaw * 180.0 / 3.14159265

  gh_object.set_position(pivot, px, py, pz)
  gh_object.set_euler_angles(pivot, 0, 0, ang_deg)
  gh_object.set_euler_angles(ring, 0, -time*angular_speed, 0)
end

gh_object.render(main_object)




if (wireframe == 1) then
  gh_renderer.solid()
end








-- Display light spheres just to see the position of lights -----------------------
--
if (show_light_sphere == 1) then
  gh_gpu_program.bind(color_prog)
  gh_object.set_position(light_sphere, light0_pos.x, light0_pos.y, light0_pos.z)
  gh_object.render(light_sphere)
  gh_object.set_position(light_sphere, light1_pos.x, light1_pos.y, light1_pos.z)
  gh_object.render(light_sphere)
end



-- Reference grid ------------------
--
if (show_ref_grid == 1) then
  gh_gpu_program.bind(color_prog)
  gh_object.render(grid)
end











---------------------------------------------------------------------------------
-- ImGui interface / control panel
---------------------------------------------------------------------------------
---[[
gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.4, 0.4, 0.6, 0.25)

if (imgui_begin(350, winH) == 1) then

	local window_w = gh_imgui.get_content_region_available_width()


	local widget_width = window_w * 0.95
	gh_imgui.push_item_width(widget_width)


  gh_imgui.text_rgba(string.format("FPS:%d (dt:%.2f msec)", fps, dt*1000), 1.0, 1.0, 1.0, 1.0)

  gh_imgui.text_rgba("GL_RENDERER: ", 1.0, 1.0, 1.0, 1.0)
	gh_imgui.widget(IMGUI_WIDGET_SAME_LINE)
  gh_imgui.text_rgba(gl_renderer, 1.0, 1.0, 0.0, 1.0)

  gh_imgui.text_rgba("GL_VERSION: ", 1.0, 1.0, 1.0, 1.0)
	gh_imgui.widget(IMGUI_WIDGET_SAME_LINE)
  gh_imgui.text_rgba(gl_version, 1.0, 0.7, 0.0, 1.0)

	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_SEPARATOR)

	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
  
  

	--[[
  local button_width = 208
  if (gh_imgui.button("myKoolButton", button_width, 20) == 1) then
    -- do something
  end
  --]]

  
 



	gh_imgui.text("Background top color:")
	bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a = gh_imgui.color_edit_rgba("##coloredit-bkg_color_top", bkg_color_top.r, bkg_color_top.g, bkg_color_top.b, bkg_color_top.a)

  gh_imgui.text("Background bottom color:")
  bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a = gh_imgui.color_edit_rgba("##coloredit-bkg_color_bottom", bkg_color_bottom.r, bkg_color_bottom.g, bkg_color_bottom.b, bkg_color_bottom.a)


	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)

  --use_textures = gh_imgui.checkbox("Use textures", use_textures)
  if (is_rpi == 0) then
    show_ref_grid = gh_imgui.checkbox("Show reference grid", show_ref_grid)
  end
  show_light_sphere = gh_imgui.checkbox("Show light sphere", show_light_sphere)
  wireframe = gh_imgui.checkbox("Wireframe", wireframe)
  
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.text(string.format("Camera: <%.3f ; %.3f ; %.3f>", cx, cy, cz))

	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
	gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)


  gh_imgui.widget(IMGUI_WIDGET_SEPARATOR)
  gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)
  gh_imgui.widget(IMGUI_WIDGET_VERTICAL_SPACING)

  local min_value = 1.0
  local max_value = 100.0
  local power = 1.0 -- Use power!=1.0 for logarithmic sliders.
  gh_imgui.text("Angular speed")
  angular_speed = gh_imgui.slider_1f("##angular_speed", angular_speed,   min_value, max_value,  power)


  
	gh_imgui.pop_item_width()

end

imgui_end()
