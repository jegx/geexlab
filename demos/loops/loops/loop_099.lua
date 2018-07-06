function loop_init()

  -- The core of this demo: it's a hierarchy of objects:
  -- main_ring
     --> ring 0
         --> ring
             --> cube 0
             --> ...
             --> cube 15

     --> ...
         --> ring
             --> cube 0
             --> ...
             --> cube 15

     --> ring 7
         --> ring
             --> cube 0
             --> ...
             --> cube 15
  --         
  -- The hierarchy makes it possible to code in a simple way a complex animation.
  --
  --
  -- Based on https://github.com/spite/looper/blob/master/loops/104.js
  --
  --


  local ang_step = TAU / num_cubes 
  local ang_step_deg = ang_step * 180.0 / PI

  for j=0, num_rings-1 do
    local pivot = gh_object.create()
    pivots[j+1] = pivot

    gh_node.add_child(main_object, pivot)

    local ring = gh_object.create()
    gh_node.add_child(pivot, ring)
    rings[j+1] = ring

    local ang = 0

    local r = 0.0
    local g = 0.0
    local b = 0.0

    r, g, b = hsl_to_rgb(.25-.5*j/num_rings,.65,.5)

    for i=0, num_cubes-1 do

      local box = gh_mesh.create_box(cube_size, cube_size, cube_size, 2, 2, 2)

      gh_mesh.set_vertices_color(box, r, g, b, 1.0)

      local ma = i * ang_step
      local px = ring_radius * math.cos(ma) 
      local pz = ring_radius * math.sin(ma) 
      
      gh_object.set_position(box, px, 0.0, pz)
      gh_object.set_euler_angles(box, 0, ang*180.0/PI, 0)

      ang = ang - ang_step

      gh_node.add_child(ring, box)
    end

  end

end



function loop_frame(time)

  -- The RINGS ------------------------------------------
  -- Thanks to the hierarchy that allows to group objects together, we can easily rotate
  -- a ring made up of several cubes. And several rings need to be rotated...
  --
  --
  local ang_step = TAU / num_rings 

  --local time = elapsed_time

  ring_radius = 5.5

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


end  



PI = 3.14159265
TAU = 2.0 * PI

main_object = gh_object.create()
pivots = {}
rings = {}


-- Rings params.
num_rings = 16
--num_rings = 32

ring_radius = 4

--num_cubes = 32 -- cubes per ring
--cube_size = 0.5

num_cubes = 64 -- cubes per ring
cube_size = 0.25

angular_speed = 20




--[[
loop_099 = {
  
  PI = 3.14159265,
  TAU = 2.0 * loop_099.PI,

  main_object = gh_object.create(),
  pivots = {},
  rings = {},


  -- Rings params.
  num_rings = 16,
  --num_rings = 32,

  ring_radius = 4,

  --num_cubes = 32, -- cubes per ring
  --cube_size = 0.5

  num_cubes = 64, -- cubes per ring
  cube_size = 0.25,

  init = loop_099_init,
  frame = loop_099_frame
}
--]]
