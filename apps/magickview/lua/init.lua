    
local demo_dir = gh_utils.get_demo_dir()    
local lib_dir = gh_utils.get_scripting_libs_dir()     

dofile(lib_dir .. "lua/libfont/libfont1.lua")   
dofile(lib_dir .. "lua/imgui.lua")    





winW, winH = gh_window.getsize(0)


camera_ortho = gh_camera.create_ortho(-winW/2, winW/2, -winH/2, winH/2, 1.0, 10.0)
gh_camera.set_viewport(camera_ortho, 0, 0, winW, winH)
gh_camera.set_position(camera_ortho, 0, 0, 4)




dofile(demo_dir .. "lua/init_shaders.lua")
--vertex_color_prog = gh_node.getid("vertex_color_prog") 
--texture_prog = gh_node.getid("texture_prog")
--gh_gpu_program.uniform1i(texture_prog, "tex0", 0)



is_rpi = 0
if (gh_utils.get_platform() == 4) then 
  is_rpi = 1
end



if (is_rpi == 1) then 
  dofile(demo_dir .. "lua/init_mouse_rpi.lua")
  mouse_init()
end




quad = gh_mesh.create_quad(256, 256)

selection_quad = gh_mesh.create_quad(16, 16)
gh_mesh.set_vertices_color(selection_quad, 0.5, 0.5, 0.8, 0.5)
gh_mesh.resize_quad(selection_quad, 0, 0) -- invisible quad

-- gh_mesh.set_vertex_color(selection_quad, 0, 1.0, 0.0, 0.0, 1.0)
-- gh_mesh.set_vertex_color(selection_quad, 1, 0.0, 1.0, 0.0, 1.0)
-- gh_mesh.set_vertex_color(selection_quad, 2, 0.0, 0.0, 1.0, 1.0)
-- gh_mesh.set_vertex_color(selection_quad, 3, 1.0, 1.0, 0.0, 1.0)


tex0 = 0









image_negate = 0
image_quantize = 0
image_posterize = 0
image_sketch = 0
image_solarize = 0
image_swirl = 0
image_emboss = 0
image_charcoal = 0
image_crop = 0
image_oil_paint = 0
image_encipher = 0
image_decipher = 0
image_flip = 0
image_flop = 0
image_transpose = 0
image_wave = 0

image_info = ""
load_image_dnd = 0
load_image = 0
save_image = 0
filename_src = ""
filename_dst = ""
image_src_w = 0
image_src_h = 0
exif_info = {}
exif_num_props = 0


need_init_selection_quad = 1
selection_start_x = 0
selection_start_y = 0
selection_end_x = 0
selection_end_y = 0
old_mouse_x = 0
old_mouse_y = 0

image_selection_start_x = 0
image_selection_start_y = 0
image_selection_end_x = 0
image_selection_end_y = 0

image_selection_rect = {x=0, y=0, w=0, h=0}


image_quad_w = 0
image_quad_h = 0


g_is_imgui_window_hovered = 0


gh_renderer.set_vsync(1)






------------------------------------------------------------------

function UpdateQuadSize()
  if (tex0 > 0) then
    local w, h = gh_texture.get_size(tex0)
    image_src_w = w
    image_src_h = h
    ---[[
    if (w > (0.9*winW)) then
      local ratio = w/h
      w = 0.9*winW
      h = w/ratio
    end  

    if (h > (0.9*winH)) then
      local ratio = w/h
      h = 0.9*winH
      w = h * ratio
    end  
    --]]

    image_quad_w = w
    image_quad_h = h
    gh_mesh.resize_quad(quad, w, h)

  end
end



function update_exif_data(filename)
  -- Read EXIF info
  --
  gh_imagemagick.file_exif_to_log(filename)

  local num_props = gh_imagemagick.file_exif_get_num_properties(filename)
  for i=1, num_props do
    local property_name, property_value = gh_imagemagick.file_exif_get_property(filename, i-1)
    exif_info[i] = {name=property_name, value=property_value}
  end
  exif_num_props = num_props
end









------------------------------------------------------------------
-- Load a default image
------------------------------------------------------------------

filename_src = demo_dir .. "flower_jegx.jpg"

local im_width, im_height, im_format = gh_imagemagick.file_ping(filename_src)
image_info = string.format("image info - width:%0.f - height:%0.f - format:%s", im_width, im_height, im_format)
print(image_info)

-- Read EXIF info
--
update_exif_data(filename_src)



local PF_U8_RGB = 1
local PF_U8_RGBA = 3
local pixel_format = PF_U8_RGBA

local gen_mipmaps = 0
local free_cpu_memory = 0
local upload_to_gpu = 1
tex0 = gh_imagemagick.texture_create_from_file(filename_src, pixel_format, gen_mipmaps, free_cpu_memory, upload_to_gpu)

UpdateQuadSize()

load_image = 0



