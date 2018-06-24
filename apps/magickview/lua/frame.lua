
function mouse_get_position()
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


function ResetSelectionQuad()
    gh_mesh.set_vertex_position(selection_quad, 0, 0, 0 , 0, 1.0) -- bottom-left
    gh_mesh.set_vertex_position(selection_quad, 1, 0, 0, 0, 1.0) -- top-left
    gh_mesh.set_vertex_position(selection_quad, 2, 0, 0, 0, 1.0) -- top-right
    gh_mesh.set_vertex_position(selection_quad, 3, 0, 0, 0, 1.0) -- bottom-right

    image_selection_start_x = 0
    image_selection_end_x = 0

    image_selection_start_y = 0
    image_selection_end_y = 0

    image_selection_rect.x = 0
    image_selection_rect.y = 0
    image_selection_rect.w = 0
    image_selection_rect.h = 0
end




local elapsed_time = gh_utils.get_elapsed_time()



-- Selection quad management: size in 2D/screen space and size in image space.
--
if (g_is_imgui_window_hovered == 0) then

  local LEFT_BUTTON = 1
  local mouse_left_button = gh_input.mouse_get_button_state(LEFT_BUTTON) 
  if (mouse_left_button == 1) then
    local mouse_x, mouse_y = mouse_get_position()
    local dx = mouse_x - old_mouse_x
    local dy = mouse_y - old_mouse_y
    old_mouse_x = mouse_x
    old_mouse_y = mouse_y

    if (need_init_selection_quad == 1) then
      need_init_selection_quad = 0
      selection_start_x = mouse_x
      selection_start_y = mouse_y
      selection_end_x = selection_start_x
      selection_end_y = selection_start_y
    else
      selection_end_x = selection_end_x + dx
      selection_end_y = selection_end_y + dy
    end

    local start_x = selection_start_x - winW/2
    local end_x = selection_end_x - winW/2
    
    local start_y = winH/2 - selection_start_y
    local end_y = winH/2 - selection_end_y

    ------------------------------------------------------    
    -- Limit the size of the selection quad to the size if the image quad in 2D space.
    --
    if (start_x < (-image_quad_w/2)) then
      start_x = -image_quad_w/2
    end

    if (start_y > (image_quad_h/2)) then
      start_y = image_quad_h/2
    end


    if (end_x > (image_quad_w/2)) then
      end_x = image_quad_w/2
    end

    if (end_x < (-image_quad_w/2)) then
      end_x = -image_quad_w/2
    end

    if (end_y < (-image_quad_h/2)) then
      end_y = -image_quad_h/2
    end

    if (end_y > (image_quad_h/2)) then
      end_y = image_quad_h/2
    end
    ------------------------------------------------------    


    local quad_w = end_x - start_x
    local quad_h = end_y - start_y

    gh_mesh.set_vertex_position(selection_quad, 0, start_x,          start_y + quad_h, 0, 1.0) -- bottom-left
    gh_mesh.set_vertex_position(selection_quad, 1, start_x,          start_y, 0, 1.0) -- top-left
    gh_mesh.set_vertex_position(selection_quad, 2, start_x + quad_w, start_y, 0, 1.0) -- top-right
    gh_mesh.set_vertex_position(selection_quad, 3, start_x + quad_w, start_y + quad_h, 0, 1.0) -- bottom-right



    -------------------------------------------------------
    -- Compute the size of the selection rectangle in the image space so we will be able to
    -- display the real size of the selection quad with respect to real size of image.
    --
    if ((image_src_w > 0) and (image_quad_w > 0)) then
      local rx = image_quad_w / image_src_w
      local ry = image_quad_h / image_src_h

      image_selection_start_x = (start_x + image_quad_w/2) / rx
      image_selection_end_x = (end_x + image_quad_w/2) / rx

      image_selection_start_y = (image_quad_h/2 - start_y) / ry
      image_selection_end_y = (image_quad_h/2 - end_y) / ry


      if (image_selection_start_x < 0) then
        image_selection_start_x = 0
      end

      if (image_selection_start_y < 0) then
        image_selection_start_y = 0
      end

      if (image_selection_end_x > image_src_w) then
        image_selection_end_x = image_src_w
      end

      if (image_selection_end_y > image_src_h) then
        image_selection_end_y = image_src_h
      end

      image_selection_rect.x = image_selection_start_x
      image_selection_rect.y = image_selection_start_y
      image_selection_rect.w = image_selection_end_x - image_selection_start_x
      image_selection_rect.h = image_selection_end_y - image_selection_start_y
    end  
    -------------------------------------------------------

  else

    need_init_selection_quad = 1

  end  
end









--////////////////////////////////////////////////////////////////////////////////////////////
if (load_image == 1) then
  load_image = 0


  if (load_image_dnd == 0) then
    filename_src, ret = gh_utils.nfd_open_dialog("bmp,jpg,png,gif,tga", "")
  else
    ret = 1 -- The image filename comes from the Drag N Drop script.
  end

  if (ret == 1) then

    local im_width, im_height, im_format = gh_imagemagick.file_ping(filename_src)
    image_info = string.format("image info - width:%0.f - height:%0.f - format:%s", im_width, im_height, im_format)
    print(image_info)


    -- Read EXIF info
    --
    update_exif_data(filename_src)



    local PF_U8_RGB = 1
    local PF_U8_RGBA = 3
    local pixel_format = PF_U8_RGBA

    if (tex0 == 0) then
      local gen_mipmaps = 0
      local free_cpu_memory = 0
      local upload_to_gpu = 1
      tex0 = gh_imagemagick.texture_create_from_file(filename_src, pixel_format, gen_mipmaps, free_cpu_memory, upload_to_gpu)
    else
      gh_imagemagick.texture_read(tex0, filename_src, pixel_format)
    end


    --im_width = im_width/2
    --im_height = im_height/2
    --local filter_type = "box"
    --gh_imagemagick.texture_resize(tex0, im_width, im_height, filter_type)
    --gh_imagemagick.texture_update(tex0)
    --image_info = string.format("image info - width:%0.f - height:%0.f - format:%s", im_width, im_height, im_format)
    --print(image_info)


    UpdateQuadSize()
  end
end
--////////////////////////////////////////////////////////////////////////////////////////////







if (tex0 > 0) then

  -------------------------------------- SAVE IMAGE --------------------------------
  if (save_image == 1) then
    
    save_image = 0
    filename_dst = gh_utils.nfd_save_dialog("", "")
    gh_imagemagick.texture_update(tex0)
    gh_imagemagick.texture_write(tex0, filename_dst)

  end



  -------------------------------------- POSTERIZE IMAGE --------------------------------
  if (image_posterize == 1) then
    image_posterize = 0
    local num_colors = 4;
    local dither_method_type = "none"
    gh_imagemagick.texture_posterize(tex0, num_colors, dither_method_type)
    gh_imagemagick.texture_update(tex0)
  end


  -------------------------------------- QUANTIZE IMAGE --------------------------------
  if (image_quantize == 1) then
    image_quantize = 0
    local num_colors = 4;
    local color_space_type = "srgb"
    local treedepth = 1
    local dither_method_type = "none"
    gh_imagemagick.texture_quantize(tex0, num_colors, dither_method_type)
    gh_imagemagick.texture_update(tex0)
  end


  -------------------------------------- NEGATE IMAGE --------------------------------
  if (image_negate == 1) then
    image_negate = 0
    local only_negate_grayscale_pixels = 0
    gh_imagemagick.texture_negate(tex0, only_negate_grayscale_pixels)
    gh_imagemagick.texture_label(tex0, "This is a label")
    gh_imagemagick.texture_update(tex0)
  end


  -------------------------------------- SKETCH IMAGE --------------------------------
  if (image_sketch == 1) then
    image_sketch = 0
    local radius = 4.0
    local sigma = 1.0
    local angle = 30.1
    gh_imagemagick.texture_sketch(tex0, radius, sigma, angle)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- SOLARIZE IMAGE --------------------------------
  if (image_solarize == 1) then
    image_solarize = 0
    local threshold = 2000
    gh_imagemagick.texture_solarize(tex0, threshold)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- SWIRL IMAGE --------------------------------
  if (image_swirl == 1) then
    image_swirl = 0
    local degrees = 60.0
    local interpolation_method = "average4"
    gh_imagemagick.texture_swirl(tex0, degrees, interpolation_method)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- EMBOSS IMAGE --------------------------------
  if (image_emboss == 1) then
    image_emboss = 0
    local radius = 4.0
    local sigma = 1.0
    gh_imagemagick.texture_emboss(tex0, radius, sigma)
    gh_imagemagick.texture_update(tex0)
  end


  -------------------------------------- OIL PAINT IMAGE --------------------------------
  if (image_oil_paint == 1) then
    image_oil_paint = 0
    local radius = 10.0
    local sigma = 1.0
    gh_imagemagick.texture_oil_paint(tex0, radius, sigma)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- CHARCOAL IMAGE --------------------------------
  if (image_charcoal == 1) then
    image_charcoal = 0
    local radius = 4.0
    local sigma = 1.0
    gh_imagemagick.texture_charcoal(tex0, radius, sigma)
    gh_imagemagick.texture_update(tex0)
  end


  -------------------------------------- CROP IMAGE --------------------------------
  if (image_crop == 1) then
    image_crop = 0

    --image_src_w = image_selection_end_x - image_selection_start_x
    --image_src_h = image_selection_end_y - image_selection_start_y
    --gh_imagemagick.texture_crop(tex0, image_selection_start_x, image_selection_start_y, image_src_w, image_src_h)

    gh_imagemagick.texture_crop(tex0, image_selection_rect.x, image_selection_rect.y, image_selection_rect.w, image_selection_rect.h)

    gh_imagemagick.texture_update(tex0)
  
    UpdateQuadSize()
    ResetSelectionQuad()
  end

  -------------------------------------- ENCIPHER IMAGE --------------------------------
  if (image_encipher == 1) then
    image_encipher = 0
    gh_imagemagick.texture_encipher(tex0, "geexlab")
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- DECIPHER IMAGE --------------------------------
  if (image_decipher == 1) then
    image_decipher = 0
    gh_imagemagick.texture_decipher(tex0, "geexlab")
    gh_imagemagick.texture_despeckle(tex0)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- FLIP IMAGE --------------------------------
  if (image_flip == 1) then
    image_flip = 0
    gh_imagemagick.texture_flip(tex0)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- FLOP IMAGE --------------------------------
  if (image_flop == 1) then
    image_flop = 0
    gh_imagemagick.texture_flop(tex0)
    gh_imagemagick.texture_update(tex0)
  end

  -------------------------------------- TRANSPOSE IMAGE --------------------------------
  if (image_transpose == 1) then
    image_transpose = 0
    gh_imagemagick.texture_transpose(tex0)
    gh_imagemagick.texture_update(tex0)
    UpdateQuadSize()
  end

  -------------------------------------- WAVE IMAGE --------------------------------
  if (image_wave == 1) then
    image_wave = 0
    local amplitude = 20
    local wave_length = 100
    local interpolation_method = "nearest"
    gh_imagemagick.texture_wave(tex0, amplitude, wave_length, interpolation_method)
    gh_imagemagick.texture_update(tex0)
  end

end






--//////////////////////////////////////////////////////////////////////
-- Rendering all objects
--//////////////////////////////////////////////////////////////////////


gh_renderer.clear_color_depth_buffers(0.2, 0.2, 0.2, 1.0, 1.0)
gh_renderer.set_depth_test_state(0)



-- Image rendering -------------------------
--
if (tex0 > 0) then

  gh_camera.bind(camera_ortho)
  gh_texture.bind(tex0, 0)
  gh_gpu_program.bind(texture_prog)
  gh_object.render(quad)

end




-- Selection rectangle -------------------------
--
if ((image_selection_rect.w > 0) or (image_selection_rect.h > 0)) then

  gh_camera.bind(camera_ortho)
  gh_gpu_program.bind(vertex_color_prog)

  gh_renderer.set_blending_state(1)
  BLEND_FACTOR_ZERO = 0
  local BLEND_FACTOR_ONE = 1
  local BLEND_FACTOR_SRC_ALPHA = 2
  local BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 5
  local BLEND_FACTOR_SRC_COLOR = 8
  local BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 9
  gh_renderer.set_blending_factors(BLEND_FACTOR_SRC_ALPHA, BLEND_FACTOR_ONE)
  gh_object.render(selection_quad)
  gh_renderer.set_blending_state(0)

end






-- Information ------------------------------------------
--
libfont_clear()

local y_offset = 40

libfont_print(20, y_offset, 1, 1, 0, 1, "-- MagickView 0.1.0 --")
y_offset = y_offset + 30

libfont_print(20, y_offset, 0.8, 0.8, 0.8, 1, string.format("Image: %s", filename_src))
y_offset = y_offset + 20


if ((image_src_w > 0) and (image_src_h > 0)) then
  libfont_print(20, y_offset, 0.8, 0.8, 0.8, 1, string.format("Image size: %.0f x %.0f", image_src_w, image_src_h))
  y_offset = y_offset + 20
end

libfont_print(20, y_offset, 0.8, 0.8, 0.8, 1, string.format("Image selection rect: [%.0f ; %.0f - %.0f x %.0f]", image_selection_rect.x, image_selection_rect.y, image_selection_rect.w, image_selection_rect.h))
y_offset = y_offset + 20


libfont_render()








-- Control panel ------------------------------------------
--

local mouse_x, mouse_y = mouse_get_position()
local mouse_quad_x = mouse_x - winW/2
local mouse_quad_y = -(mouse_y - winH/2) 


imgui_frame_begin_v2(mouse_x, mouse_y)


--IMGUI_WINDOW_BG_COLOR = 1
gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.1, 0.1, 0.1, 0.70)


local is_open = imgui_window_begin_v1("Control panel", 300, 400, 20, 140)

if (is_open == 1) then

  local window_w = gh_imgui.get_content_region_available_width()

  local widget_width = window_w * 1.0
  
  
  gh_imgui.text("Press [ESC] to quit the demo")

  imgui_vertical_space()


  if (gh_imgui.button("Load image", 150, 20) == 1) then
    load_image = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Save image", 150, 20) == 1) then
    save_image = 1
  end

  imgui_vertical_space()
  imgui_separator()
  imgui_vertical_space()

  gh_imgui.text("Image filters:")  

  if (gh_imgui.button("Negate", 100, 20) == 1) then
    image_negate = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Quantize", 100, 20) == 1) then
    image_quantize = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Posterize", 100, 20) == 1) then
    image_posterize = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Sketch", 100, 20) == 1) then
    image_sketch = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Solarize", 100, 20) == 1) then
    image_solarize = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Swirl", 100, 20) == 1) then
    image_swirl = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Emboss", 100, 20) == 1) then
    image_emboss = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Charcoal", 100, 20) == 1) then
    image_charcoal = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Crop", 100, 20) == 1) then
    image_crop = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Oil paint", 100, 20) == 1) then
    image_oil_paint = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Encipher", 100, 20) == 1) then
    image_encipher = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Decipher", 100, 20) == 1) then
    image_decipher = 1
  end

  imgui_vertical_space()

  if (gh_imgui.button("Flip", 100, 20) == 1) then
    image_flip = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Flop", 100, 20) == 1) then
    image_flop = 1
  end

  imgui_vertical_space()


  if (gh_imgui.button("Transpose", 100, 20) == 1) then
    image_transpose = 1
  end

  imgui_same_line()

  if (gh_imgui.button("Wave", 100, 20) == 1) then
    image_wave = 1
  end



  --imgui_same_line()

  --gh_imgui.push_item_width(widget_width)
  --gh_imgui.pop_item_width()


end 

imgui_window_end()



local is_open = imgui_window_begin_v1("EXIF info", 300, 400, 340, 140)
if (is_open == 1) then
  if (exif_num_props > 0) then
    for i=1, exif_num_props do
      local info = exif_info[i]
      gh_imgui.text(info.name .. " => " .. info.value)
    end
  else
    gh_imgui.text("No EXIF info available")
  end
end 
imgui_window_end()




g_is_imgui_window_hovered = 0
if ((gh_imgui.is_any_window_hovered() == 1) or (gh_imgui.is_any_item_hovered() == 1)) then
  g_is_imgui_window_hovered = 1
end



imgui_frame_end()





if (is_rpi == 1) then 
  mouse_draw(camera_ortho, mouse_quad_x, mouse_quad_y)
end


