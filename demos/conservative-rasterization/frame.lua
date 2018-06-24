
local elapsed_time = gh_utils.get_elapsed_time()
    


local PRIMITIVE_TRIANGLE = 0
local PRIMITIVE_TRIANGLE_STRIP = 1
local PRIMITIVE_LINE = 2
local PRIMITIVE_LINE_STRIP = 3
local PRIMITIVE_LINE_LOOP = 4
local PRIMITIVE_LINE_ADJACENCY = 5
local PRIMITIVE_LINE_STRIP_ADJACENCY = 6
local PRIMITIVE_PATCH = 7
local PRIMITIVE_POINT = 8




-- Bind the render target. Now the 3D rendering goes to the render 
-- target and no longer in regular framebuffer.
--
gh_render_target.bind(rt01)
 

gh_renderer.set_viewport(0, 0, 32, 32)
gh_renderer.clear_color_depth_buffers(0.4, 0.4, 0.4, 1.0, 1.0)

gh_renderer.disable_state("GL_CULL_FACE")


gh_renderer.wireframe()


gh_renderer.set_depth_test_state(0)
gh_gpu_program.bind(cr_prog)


-- Rendering with conservative rasterization.
--
if (show_conservative_raster == 1) then

  -- Update uniforms directly in the renderer.
  gh_gpu_program.gpu_uniform1f(cr_prog, "vertexscale", 1.0)
  gh_gpu_program.gpu_uniform4f(cr_prog, "pixelcolor", 1.0, 0.5, 0.0, 1.0)


  gh_renderer.enable_state("GL_CONSERVATIVE_RASTERIZATION_NV")
  gh_renderer.conservative_rasterization_set_sub_pixel_precision_bias_nv(xbits, ybits)

  -- Attributeless rendering.
  gh_renderer.draw_primitives(PRIMITIVE_TRIANGLE, 0, 3)

  gh_renderer.disable_state("GL_CONSERVATIVE_RASTERIZATION_NV")
end



-- Normal rendering
--
gh_gpu_program.gpu_uniform4f(cr_prog, "pixelcolor", 1.0, 1.0, 1.0, 1.0)
-- Attributeless rendering.
gh_renderer.draw_primitives(PRIMITIVE_TRIANGLE, 0, 3)



gh_renderer.solid()





    
-- Back to regular framebuffer.
--  
gh_render_target.unbind(rt01)






gh_renderer.set_viewport(0, 0, winW, winH)
gh_renderer.clear_color_buffer(0.0, 0.0, 0.0, 1.0, 1.0)

gh_renderer.set_depth_test_state(0)







  
-- Binds the render target texture...
-- 
gh_texture.rt_color_bind(rt01, 0)

-- Binding of the render target viewer GPU program.
--
gh_gpu_program.bind(tex_prog)
gh_gpu_program.gpu_uniform1i(tex_prog, "tex0", 0)
gh_gpu_program.gpu_uniform1f(tex_prog, "vscale", 1.0/render_target_scale)


-- Rendering of the postfx fullscreen quad.
-- Attributeless rendering.
--
gh_renderer.draw_primitives(PRIMITIVE_TRIANGLE_STRIP, 0, 4)
  

  



---------------------------------------------------
-- ImGui interface - Control panel
--
imgui_frame_begin()

gh_imgui.set_color(IMGUI_WINDOW_BG_COLOR, 0.1, 0.1, 0.1, 0.6)

local is_open = imgui_window_begin_v1("Control panel", 400, 300, 20, 20)
if (is_open == 1) then
          
  
  gh_imgui.text_rgba("NVIDIA conservative rasterization", 1.0, 1.0, 0.0, 1.0)
  gh_imgui.text_rgba("GL_NV_conservative_raster", 1.0, 0.5, 0.0, 1.0)
  gh_imgui.text("Press [ESC] to quit the demo")

  imgui_vertical_space()
  imgui_vertical_space()
 
  gh_imgui.text("conservative_rasterization_get_properties_nv()")
  gh_imgui.text("- bias_xbits: " .. bias_xbits)
  gh_imgui.text("- bias_ybits: " .. bias_ybits)
  gh_imgui.text("- max_bias_bits: " .. max_bias_bits)
   
  imgui_vertical_space()
  imgui_vertical_space()
  imgui_vertical_space()
  imgui_vertical_space()
  
  if (show_conservative_raster == 1) then
    if (gh_imgui.button("Disable conservative rasterization", 250, 20) == 1) then
      show_conservative_raster = 0
    end
  else
    if (gh_imgui.button("Enable conservative rasterization", 250, 20) == 1) then
      show_conservative_raster = 1
    end
  end



  imgui_vertical_space()
  imgui_vertical_space()
  gh_imgui.text("Render target scale factor: ")
  render_target_scale = gh_imgui.slider_1f("##render_target_scale", render_target_scale, 1.0, 32.0, 1)


  --[[
  imgui_vertical_space()
  imgui_vertical_space()
  gh_imgui.text("Sub pixel precision")
  xbits = gh_imgui.slider_1i("xbits##subpixelprecision", xbits, 0, 8)
  ybits = gh_imgui.slider_1i("ybits##subpixelprecision", ybits, 0, 8)
  --]]

end 
imgui_window_end()

imgui_frame_end()




