winW, winH = gh_window.getsize(0)


--[[
local aspect = 1.333
if (winH > 0) then
  aspect = winW / winH
end  
gh_camera.update_persp(camera_persp, camera_fov, aspect, 0.1, 100.0)
gh_camera.set_viewport(camera_persp, 0, 0, winW, winH)
--]]

gx_camera.update_perspective(camera, camera_fov, 1, 0, 0, winW, winH, camera_znear, camera_zfar)



gh_camera.update_ortho(camera_ortho, -winW/2, winW/2, -winH/2, winH/2, 1.0, 10.0)
gh_camera.set_viewport(camera_ortho, 0, 0, winW, winH)

gh_mesh.update_quad_size(fullscreen_quad, winW, winH)


