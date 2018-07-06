function loop_init()

  -- The hierarchy makes it possible to code in a simple way a complex animation.
  --
  --
  -- Based on https://github.com/spite/looper/blob/master/loops/104.js
  --
  --


  local ang_step = TAU / num_cubes 
  local ang_step_deg = ang_step * 180.0 / PI

  for j=0, num_cubes-1 do

    local pivot = gh_object.create()

    local pivot2 = gh_object.create()
    gh_node.add_child(pivot, pivot2)
    pivots2[j+1] = pivot2


    local ma = j * TAU / num_cubes
    local mr = radius
    local mx = mr * math.cos(ma)
    local my = mr * math.sin(ma)
    local mz = 0

    gh_object.set_position(pivot, mx, my, mz)
    gh_object.set_euler_angles(pivot, 0, 0, ma*180.0/PI)


    local ta = ( j % num_loops ) * (TAU / num_loops)
    local tr = 1
    local px = tr * math.cos(ta)
    local py = 0
    local pz = tr * math.sin(ta)

    local cube = gh_mesh.create_box(cube_size, cube_size, cube_size, 2, 2, 2)
    gh_object.set_position(cube, px, py, pz)
    gh_object.set_euler_angles(cube, 0, ta*180.0/PI, 0)
    gh_node.add_child(pivot2, cube)




    local px2 = tr * math.cos(ta + PI)
    local py2 = 0
    local pz2 = tr * math.sin(ta + PI)
    local cube2 = gh_mesh.create_box(cube_size, cube_size, cube_size, 2, 2, 2)
    gh_object.set_position(cube2, px2, py2, pz2)
    gh_object.set_euler_angles(cube2, 0, (ta+PI)*180.0/PI, 0)
    gh_node.add_child(pivot2, cube2)



    local r = 0.0
    local g = 0.0
    local b = 0.0
    r, g, b = hsl_to_rgb(j/num_cubes,.75,.5)
    gh_mesh.set_vertices_color(cube, r, g, b, 1.0)
    gh_mesh.set_vertices_color(cube2, r, g, b, 1.0)




    gh_node.add_child(main_object, pivot)

  end

end



function loop_frame(time)

  for i=0, num_cubes-1 do

    local pivot2 = pivots2[i+1]

    gh_object.set_euler_angles(pivot2, 0, -time*angular_speed, 0)
  end

  gh_object.render(main_object)

end  




PI = 3.14159265
TAU = 2.0 * PI

main_object = gh_object.create()

pivots2 = {}

angular_speed = 20

radius = 4.0
num_loops = 40
num_cubes = 60 -- cubes per ring
cube_size = 0.5
