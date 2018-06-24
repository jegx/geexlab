
-- Gets the size of the 3D window. 
-- winW, winH are global.
--
winW, winH = gh_window.getsize(0)


local demo_dir = gh_utils.get_demo_dir()
dofile(demo_dir .. "super_init.lua")




-- A font for displaying some information.
-- This kind of font works only with OpenGL 2.1
-- or OpenGL 3.2+ with compatibility profile. This font
-- does not work on macOS with OpenGL 3.2+ because macOS
-- uses core profile. Look at gh_font lib for better font support
-- (an example is available in learn/01-basic/text-ttf-font/ folder 
-- of the code sample pack).
--
font = gh_utils.font_create("Tahoma", 14)



