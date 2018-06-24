------------------------------------------------------------------------
-- Helper functions for GeeXLab demos.
------------------------------------------------------------------------

--------------------------------------------------
function random(a, b)
  if (a > b) then
    local c = b
    b = a
    a = c
  end
  local delta = b-a
  return (a + math.random()*delta)
end





--------------------------------------------------
-- HLS to RGB and RGB to HSL
-- via: https://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
-- https://en.wikipedia.org/wiki/HSL_and_HSV

function hue2rgb(p, q, t)
  if(t < 0) then t = t + 1 end
  if(t > 1) then t = t - 1 end
  if(t < 1/6) then return p + (q - p) * 6.0 * t end
  if(t < 1/2) then return q end
  if(t < 2/3) then return p + (q - p) * (2.0/3.0 - t) * 6.0 end
  return p
end



function hsl_to_rgb(h, s, l)
  local r, g, b

  if (s == 0.0) then
    r = l  -- achromatic
    g = l  -- achromatic
    b = l  -- achromatic
  else
    local q = 0.0

    if (l < 0.5 ) then
      q = l * (1.0 + s) 
    else
      q = l + s - l * s
    end

    local p = 2.0 * l - q
    r = hue2rgb(p, q, h + 1.0/3.0)
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1.0/3.0)
  end

  return r, g, b
end


function rgb_to_hsl(r, g, b)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l = (max + min) / 2.0

  if(max == min) then
    h = 0
    s = 0 -- achromatic
  else
    local d = max - min
    local s = 0
    if (l > 0.5) then
      s = d / (2 - max - min)
    else
      s = d / (max + min)
    end
    
    if (max == r) then
      local x = 0.0
      if (g < b) then
        x = 6.0
      end
      h = (g - b) / d + x

    elseif (max == g) then
      h = (b - r) / d + 2
    
    elseif (max == b) then
      h = (r - g) / d + 4

    end

    h = h / 6.0
  end
  return h, s, l
end

--------------------------------------------------
