
local elapsed_time = gh_utils.get_elapsed_time()


-- Clear the background with an uniform color.
-- Each channel of an RGB color ranges from 0.0 to 1.0. 
-- Some examples:
--  white color = [1.0, 1.0, 1.0]
--  red color =   [1.0, 0.0, 0.0]
--  green color = [0.0, 1.0, 0.0]
--  bleu color =  [0.0, 0.0, 1.0]
--
gh_renderer.clear_color_buffer(0.0, 0.2, 0.2, 1.0)


-- Font position is relative to screen coordinates. The position (0, 0) is the top-left corner.
-- The position of the center of the screen is (screen_width/2, screen_height/2)
--
local x = 10
local y = 100

gh_utils.font_render(font, x, y, 0.2, 1.0, 0.0, 1.0, "Hello World from GeeXLab!")
gh_utils.font_render(font, 10, y+40, 0.6, 0.6, 0.6, 1.0, string.format("Elapsed time: %.3f sec.", elapsed_time))

gh_utils.font_render(font, 10, y+60, 0.9, 0.5, 0.1, 1.0, string.format("Window size: %d x %d", winW, winH))



-- Move a text around the screen center
--
x = winW/2 + 20 * math.sin(elapsed_time * 2.0)
y = winH/2 + 20 * math.cos(elapsed_time * 2.0)
gh_utils.font_render(font, x, y, 1.0, 1.0, 0.1, 1.0, string.format("<x:%.0f - y:%.0f>", x, y))



-- Text at the four corners of the screen.
--

x = 5
y = 0
gh_utils.font_render(font, x, y, 1.0, 1.0, 0.1, 1.0, string.format("[x:%.0f - y:%.0f]", x-5, y))

x = winW-85
y = 0
gh_utils.font_render(font, x, y, 1.0, 1.0, 0.1, 1.0, string.format("[x:%.0f - y:%.0f]", x+85, y))

x = winW-105
y = winH-20
gh_utils.font_render(font, x, y, 1.0, 1.0, 0.1, 1.0, string.format("[x:%.0f - y:%.0f]", x+105, y+20))

x = 5
y = winH-20
gh_utils.font_render(font, x, y, 1.0, 1.0, 0.1, 1.0, string.format("[x:%.0f - y:%.0f]", x-5, y+20))

