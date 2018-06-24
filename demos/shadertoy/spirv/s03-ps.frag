#version 450

layout (location = 0) in vec4 v_color;
layout (location = 1) in vec4 v_texcoord;


layout (std140, binding = 0) uniform uniforms_t
{ 
  mat4 ViewProjectionMatrix;
  mat4 ModelMatrix;
  vec4 param1;     
} ub;


layout (binding = 1) uniform sampler2D iChannel0;

layout (location = 0) out vec4 FragColor;




float iTime = ub.param1.z;
vec2 iResolution = ub.param1.xy;




// Original code: https://www.shadertoy.com/view/4l2cD3


/*

  Dual 3D Truchet Tiles
  ---------------------

  This is yet another 3D Truchet example, but it consists of two unique Truchet blocks, which gives 
  the pattern a bit more variation. Truchet patterns usually make use of one block, consisting
  of three strategically placed tori designed to intersect the centers of all cube faces.

  This particular pattern introduces another variation that consists of two tori intersecting four 
  faces and a straight segment that runs through opposing faces. The resultant pattern has more of a 
  random pipework look -- as opposed to the standard snake-like one. By the way, you could save a 
    lot of extra decision making and use just the second tile, but I feel the pattern lacks a little
  variance when doing that.
  
  Anyway, apart from some extra decision making and construction, the code doesn't differ too much 
  from regular examples. By the way, I can thank Mattz for reminding me of a concept that I'd forgotten, 
  which helped me speed up the distance field equation. Without it, this example would run much slower.
  I've described it briefly somewhere in among the distance field setup.

  Whilst on the subject of optimization, I should probably mention that I often take shortcuts with
  the distance field equations in order to save the GPU extra calculations. For instance, I'll use a 
  bound, like "max(max(x, y), z)," for a cube instead of the correct - but usually more expensive - 
  one. For the most part, you can get away with it, but things like shadows, etc, can be affected. 
  IQ has an example that illustrates the point here:

  Rotational symmetry - iq
  https://www.shadertoy.com/view/XtSczV

  
  Based on:

  // Same concept, but with one tile, which makes it easier to comprehend.
  Cubic Truchet Pattern - Shane
  https://www.shadertoy.com/view/4lfcRl

  Other Truchet examples:

  // 3D Truchet flow. Very cool. If you have easy questions to ask, feel free to send me an email, 
    // but if you have difficult ones, ask Mattz. :)
  random cubic Truchet flow - mattz
  https://www.shadertoy.com/view/MtSyRz

  // Psuedo 3D version, rendered in an oldschool game style.
  2D Pipe Pattern - Shane
  https://www.shadertoy.com/view/XlXBzl


*/


// Maximum ray distance.
#define FAR 80.

// Cross-sectional shape.
// 0, 1, 2, or 3: Round, square, rounded-square or octagonal.
#define TUBE_SHAPE 3 

// Cheap, last minute camera weave. Suggested by ExNihilo. To implement this properly, I need
// add a few lines to set up a proper "too" and "from" camera... add a camera path function...
// maybe later. :)
//#define CAMERA_WEAVE


// Global storage vectors for object identification: I'm not fond of using globals inside distance field
// functions, but felt it was necessary in this case.
vec3 vObjID;
//float gID; 

// Global glow variable. Accumulated in the raymarching function.
float glow;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n ){
    
    n = max(abs(n), 0.001);
    n /= dot(n, vec3(1));
  vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
    
}


// IQ's correct box formula.
float sdBox( vec2 p, float b ){
  //vec2 d = abs(p) - b; // "p" is already in absolute form, in this case.
  vec2 d = p - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// Tube: Cylindrical tube, square tube, etc. In this case, it's a squarish tube with some
// beveled sides.
float tube(vec2 p, float sc, float rad){
    
    // Normally needed, but in this example "p" is passed to the function in its absoluted form.
    //p = abs(p);
    
    
    #if TUBE_SHAPE == 0
    
    return length(p) - rad; // Standard round pipes.

    #elif TUBE_SHAPE == 1
    
    // Box shape: I've left the correct and cheap version for comparison. Uncomment each, then
    // pause and check the shadows. The structure remains the same, but the shadows do not.
    return sdBox(p, rad); // Correct square distance field equation.
    //return max(p.x, p.y) - rad; // Cheaper shortcut. Almost the same, but not quite.
    
    #elif TUBE_SHAPE == 2
    // Rounded square tube. Two versions.
    return smax(p.x, p.y, .015) - rad; // Rounded square. Smooth minimum version.
    //return pow(dot(pow(p, vec2(8)), vec2(1)), 1./8.) - rad; // Rounded square. Super-elliptical.
    
    #else
    
    // Ocatagonal shape.
    return max(max(p.x, p.y), (p.x + p.y)*sc) - rad; // .7071 for an octagon.
    
    #endif
    
}


// The toroidal tube objects. Each consist of a white squarish outer tube, a similar colored 
// inner one (only visible through the holes) and some colored bands.
vec4 torTube(vec3 p){


    // Tube width.
    const float rad2 = .07;
    
    
    // Main tube. If it were not for the additional tube decorations, the following 
    // would be all that'd be required.
    //
    // Note that we're converting one of the coordinates to its circular form. That way, 
    // we're rendering a circular tube, instead of a straight one. It's an oversimplification, 
    // but that's basically all a torus is. By the way, it doesn't have to be circular, 
    // converting "p.xy" to an octagonal form, etc, would work also.
    float tb = tube(abs(vec2(length(p.xy) - .5, p.z)), .75, rad2);
    

    
    // Adding some details to the tube. 
    
    
    // Inner tube for colored lights.
    float innerTb = 1e5; //tb + .0075; 
    
   
    
    // Tube segments - for the bands and holes.
    //
    // Number of tube segments. Breaking a circle into 8 lots of 3. Other combinations can
    // work though.
    const float aNum = 12.; 
    
    // Realigning the segments.
    p.xy = rot2(3.14159/4.)*p.xy;
    
    // To place things evenly around the tube, you need to obtain the angle subtended to the center,
    // partition it into the required number of cells (aNum), then obtain the angle at the center.
    float a = atan(p.y, p.x);    
    float ia = floor(a/6.283*aNum) + .5; // .5 to move to the cell center.

    // Converting to polar coordinates - In effect: Radial position, "p.x," and angular position, "p.y."
    p.xy = rot2(ia*6.283/aNum)*p.xy;
    // The radial coordinate effective starts off at the center, so to spread the objects out, you have
    // to advance them  along the radial coordinate in the radial direction. In this case, we want the 
    // objects to have the same radius as the torus we're attaching them to, which is ".5."
    p.x -= .5;

    // Drawing the objects within each of the partitioned cells. In this case, we're rendering some 
    // colored sleeves (or bands), and boring out some holes.
    
    p = abs(p);
    
    // Bands, or sleeves.
    float band = max(tube(p.xz, .75,  rad2 + .0075), p.y - .06);
    vec2 peg = vec2(tube(p.xy, .64, .0425), tube(p.yz, .64, .0425)); 
    
    
    // Group the 24 cell partitions into groups of 3 - in order to cover every third cell with the 
    // band and create a portal in the others... I figured it'd break up the monotony. :)
    // On a side note, I try to avoid "if" statements inside distance functions when I can, but I 
    // figured this would be the best way for readability. Although, I might rework it later.
    if(mod(ia + 1., 3.)>2.){
        
        band = min(band, max(tube(p.xz, .6, rad2 + .015), p.y - .04));
      //band = max(band, min(band + .005, -p.y + .015));
        band = min(band, max(tube(p.xz, .6, rad2 + .025), p.y - .04/3.));
    }
    else {
        
        // Portals on alternate bands.
        
        float hole = min(peg.x, peg.y);
        
        // Octagonal portal flush. The rest are raised a little. No reason. Just a design choice.
        #if TUBE_SHAPE == 3
        band = min(band, min(max(peg.x, p.z - rad2 - .0075), max(peg.y, p.x - rad2 - .0075)));
        #else 
        band = min(band, min(max(peg.x, p.z - rad2 - .02), max(peg.y, p.x - rad2 - .02)));
        #endif
        band = max(band, -(hole + .015));
        
        tb = max(tb, -(hole + .015));
        
        // Inner tube. Actually, just some spheres at the portal positions, but to the observer,
        // it gives the impression of an inner tube.
        innerTb = length(p) - rad2 + .01;
        
    }
    

    
    // Return the tube, bands, and inner tube objects.
    return vec4(tb, band, innerTb, ia);
}




// The toroidal tube objects. Each consist of a white squarish outer tube, a similar colored 
// inner one (only visible through the holes) and some colored bands.
vec4 straightTube(vec3 p){
    
    
    // Tube width.
    const float rad2 = .07;
    
    
    // Main tube. If it were not for the additional tube decorations, the following 
    // would be all that'd be required.
    float tb = tube(abs(p.xy), .75, rad2);
    
    
    // Inner tube for colored lights.
    float innerTb = 1e5; //tb + .0075; 
    
    
    // Adding some details to the tube.

    float band = 1e5;
    const float aNum = 1.;

    
    float ia = floor(p.z*3.*aNum);

    float opz = mod(p.z + 1./aNum/3., 1./aNum);
    
    p.z = mod(p.z, 1./aNum/3.) - .5/aNum/3.;
  p = abs(p);
    
    // Bands, or sleeves.
    band = max(tb - .0075, p.z - .06);
    vec2 peg = vec2(tube(p.xz, .64, .0425), tube(p.yz, .64, .0425)); 

    
    if(opz>2./aNum/3.){
  
        band = min(band, max(tube(p.xy, .6, rad2 + .015), p.z - .04));
      //band = max(band, min(band + .005, -p.z + .015));
        band = min(band, max(tube(p.xy, .6, rad2 + .025), p.z - .04/3.));
    }
    else {
    
        // Portals on alternate bands.
        
        float hole = min(peg.x, peg.y);
        
        // Octagonal portal flush. The rest are raised a little. No reason. Just a design choice.
        #if TUBE_SHAPE == 3
        band = min(band, min(max(peg.x, p.y - rad2 - .0075), max(peg.y, p.x - rad2 - .0075)));
        #else
        band = min(band, min(max(peg.x, p.y - rad2 - .02), max(peg.y, p.x - rad2 - .02)));
        #endif
        band = max(band, -(hole + .015));
        
        tb = max(tb, -(hole + .015));
        
                // Inner tube. Actually, just some spheres at the portal positions, but to the observer,
        // it gives the impression of an inner tube.
        innerTb = length(p) - rad2 + .01;
        
    }

    
    // Return the tube, bands, and inner tube objects.
    return vec4(tb, band, innerTb, ia);
    
    
}



// I can thank Mattz for reminding me of this. You don't need to call all three decorated tubes,
// then determine the minimum. You can determine the minimum main tube, then call the function
// for the tube containing the more elaborate detailing that corresponds to it. And by that I
// mean return the unique oriented point that corresponds to the nearest tube segment distance.
//
vec4 torTubeTest(vec3 p){
    
    vec2 v = vec2(length(p.xy) - .5, p.z);
    
    // Main tube distance squared. Note: If a + c < b + c, then a*a<b*b.
    // Ie: we don't need to test length(v) - r, just dot(v, v);
    return vec4(p, dot(v, v));
}

vec4 straightTubeTest(vec3 p){
    
    vec2 v = p.xy;
    
    // Main tube distance squared. Note: If a + c < b + c, then a*a<b*b.
    // Ie: we don't need to test length(v) - r, just dot(v, v);
    return vec4(p, dot(v, v));
}


/*

  The Truchet pattern:

  A standard 3D Truchet tile consists of three toroids centered on three edges of a cube, 
    positioned to enter and exit six cube faces... Look one up on the internet, and that 
  diatribe will make more sense. :) The idea is to connect the tiles in a 3D grid, then 
  randomly rotate each around one of the axes to produce an interesting spaghetti looking 
  pattern.

  Constructing the individual tiles is as simple as breaking space into a cubic grid then
  positioning three tori in each cell. If you can position, rotate and render a torus,
  then it should be rudimentary.

  This example uses an additional block consisting of a straight tube connecting two
  opposite faces and two tori to connect the other four. That should be easy enough to
  construct too.

*/

float map(vec3 p)
{
 
    // Random ID for each grid cube.
    float rnd = fract(sin(dot(floor(p + vec3(111, 73, 27)), vec3(7.63, 157.31, 113.97)))*43758.5453);
    float rnd2 = fract(rnd*41739.7613 + .131);

    // Partition space into a grid of unit cubes - centered at the origin and ranging from
    // vec3(-.5, -.5, -.5) to vec3(-.5, -.5, -.5).
    p = fract(p) - .5;
      
    // Use each cube's random ID to rotate it in such a way that another one of its faces is 
    // facing forward. In case you're not aware, the swizzling below is a cheap trick used to
    // achieve this. By the way, there may be a faster way to write the conditionals - using 
    // ternary operators, or something to that effect, but I'm leaving it this way for now... 
    // However, if a GPU expert feels that it's unnecessarily slow, then feel free to let me 
    // know, and I'll change it.
    if(rnd>.833) p = p.xzy;
    else if(rnd>.666) p = p.yxz;
    else if(rnd>.5) p = p.yzx;
    else if(rnd>.333) p = p.zxy;
    else if(rnd>.166) p = p.zyx;
        
    // I can thank Mattz for reminding me of this step. Each Truchet tile contains three decorated
    // tubes. However, you only need to find the closest tube, "not" the closest decorated tube, which
    // requires a lot more GPU power. Each of these return the closest point and the distance...
    // Actually, the squared distance, which for comparisson purposes, is the same thing.
    vec4 tb1, tb2, tb3;
    tb1 = torTubeTest(vec3(p.xy + .5, p.z));
    if(rnd2>.66){
      
      tb2 = torTubeTest(vec3(p.yz - .5, p.x));
      tb3 = torTubeTest(vec3(p.xz - vec2(.5, -.5), p.y));
    }
    else {
      
      tb2 = torTubeTest(vec3(p.xy - .5, p.z));
      tb3 = straightTubeTest(p);  
    }
     
    // Sort the distances, then return the closest point.
    p = tb1.w<tb2.w && tb1.w<tb3.w ? tb1.xyz : tb2.w<tb3.w ? tb2.xyz : tb3.xyz;
 
    // Render the randomly aligned Truchet block. Ie, the three tori - plus bells and whistles.
    // Each quarter torus consists of three separate objects: A white tube with some holes in it, 
    // some bracing (the colored sleeve looking things) and a colored inner tube. That's nine
    // objects returned in all. If it were not for the need to sort objects and attain a segment
    // identifier (tb.w), only a float would be necessary.
    vec4 tb;
    
    if(rnd2<=.66 && tb3.w<tb1.w && tb3.w<tb2.w) tb = straightTube(p);
    else tb = torTube(p);
        

    /// A unique angular segment identifier - Not used here.
    //gID = tb.w;
    
     
    // Each torus segment contains three individual objects. Here, we're finding the minimum in
    // each category. We're keeping a global copy here that will be sorted for object identification
    // outside the raymarching loop. The reason this step is necessary is because the line below
    // finds the closest object, but doesn't tell us which object that is. That requires sorting,
    // which is best done outside the loop, for speed reasons.
    vObjID = tb.xyz;
    
    // Finding the minimum of the above to determine the overall minimum object in the scene.
    return min(min(vObjID.x, vObjID.y), vObjID.z);
    
    
}


/*
// Recreating part of the distance function to obtain the segment IDs, which in turn is used
// to create the blink effect.
float lightBlink(vec3 p, float gID){
    
    // Unique identifier for the cubic grid cell.
    float rnd = fract(sin(dot(floor(p + vec3(111, 73, 27)), vec3(7.63, 157.31, 113.97)))*43758.5453);
 
    // Reusing "rnd" to produce a new random number, then using that
    // random number to create lights that blink at random intervals.
    rnd = fract(rnd + gID*43758.54571);
    
    // Blink at random.
    return smoothstep(0.33, .66, sin(rnd*6.283 + iTime*3.)*.5 + .5);

    
}
*/


// Standard raymarching algorithm.
float trace(vec3 o, vec3 r){
    
    glow = 0.;
    
    // Total ray distance travelled, and nearest distance at the current ray position.
    float t = 0., d, ad;
    
    for (int i = 0; i<128; i++) {
        
        // Surface distance.
        d = map(o + r*t);
        ad = abs(d);
        
        // Applying some glow. There are better ways to go about it, but this will do.
        //if(ad<.25) glow += (.25 - ad)/(1. + d*8.);
        //if(ad<.25) glow += (.25 - ad)/(.25 + ad*ad);
        glow += 1./(1. + ad*ad*8.);
        //if(vObjID.z<vObjID.x && vObjID.z<vObjID.y && ad<.25) glow += (.25 - ad))/(1. + t);
        
        // If the ray position is within the surface threshold ("abs" means either side of the 
        // surface), or if we've traversed beyond the maximum, exit the loop.
        if(ad<.001*(t*.125 + 1.) || t>FAR) break;
        
        // Standard jump.
        t += d; 
        
        // Shortening the ray jump right near the camera to alleviated near-camera artifacts.
        //t += t<.125 ? d*.7 : d; 
    }
    
    // Clamp the total distance to "FAR." It can sometimes get rid of far surface artifacts.
    return min(t, FAR);
}

// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float shadow(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 32; 
    
    vec3 rd = lp-ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .001*(t*.125 + 1.);  // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        dist += clamp(h, .01, .2); 
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0.0 || dist > end) break; 
    }

    // I sometimes add a constant to the final shade value, which lightens the shadow a bit. It's a preference 
    // thing. Really dark shadows look too brutal to me. Sometimes, I'll also add AO, just for kicks. :)
    return min(max(shade, 0.) + .0, 1.); 
    
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cAO(in vec3 p, in vec3 n)
{
  float sca = 1.25, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = .01 + float(i)*.5/4.;        
        float dd = map(p + hr*n);
        occ += (hr - dd)*sca;
        sca *= .7;
    }
    return clamp(1. - occ, 0., 1.);   
    
}


// Normal calculation, with some edging and curvature bundled in.
vec3 nrm(vec3 p, inout float edge, inout float crv, float t) { 
  
    // It's worth looking into using a fixed epsilon versus using an epsilon value that
    // varies with resolution. Each affects the look in different ways. Here, I'm using
    // a mixture. I want the lines to be thicker at larger resolutions, but not too thick.
    // As for accounting for PPI; There's not a lot I can do about that.
    vec2 e = vec2(1./mix(400., iResolution.y, .5)*(1. + t*.5), 0);

  float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
  float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
  float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
  float d = map(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
/*    
    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
  d1 = map(p + e.xyy), d2 = map(p - e.xyy);
  d3 = map(p + e.yxy), d4 = map(p - e.yxy);
  d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
*/
    
    e = vec2(.002, 0); //iResolution.y - Depending how you want different resolutions to look.
  d1 = map(p + e.xyy), d2 = map(p - e.xyy);
  d3 = map(p + e.yxy), d4 = map(p - e.yxy);
  d5 = map(p + e.yyx), d6 = map(p - e.yyx);
  
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

 
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // Aspect correct screen coordinates.
  vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    
    // Ray origin, or camera - Moving along the Z-axis.
    float tm = iTime;
    #ifdef CAMERA_WEAVE
    tm *= .75;
    #endif
    
    vec3 o = vec3(0, 0, tm); 
    // Light. Situated near the camera whilst moving along with it.
  //vec3 lp = vec3(-1, 3, -.25) + o;
    vec3 lp = o + vec3(-1, 3, -1);
    
    // Cheap, last minute camera weave. Suggested by ExNihilo. To implement this properly, I need to add
  // add a few lines to set up a proper "too" and "from" camera... add a camera path function...
    // maybe later. :)
    #ifdef CAMERA_WEAVE
    o.x += sin(tm * 3.14159265/6. + 1.5707963);
    #endif
    
    // Unit ray vector.
    //vec3 r = normalize(vec3(uv, 1));
    // Slight bulbous scene warp.
    vec3 r = normalize(vec3(uv, 1.15));
    r = normalize(vec3(r.xy, r.z - length(r.xy)*.15));
    
    // Rotating "r" back and forth along various axes for some cheap camera movement. 
    #ifdef CAMERA_WEAVE
    r.xz *= rot2(-sin(tm/2. - 1.5707963) * 0.6);
    r.xy *= rot2(-sin(tm/2. - 1.5707963) * 0.4);
    //r.yz *= rot2(-sin(tm/2.) * 0.2);
    #else
    r.xz *= rot2(sin(tm/2.) * 0.4);
    r.xy *= rot2(cos(tm/2.) * 0.2);
    #endif
    
    // Trace out the scene.
    float t = trace(o, r);
     
    // Determining the object ID. Sorting the three different objects outside the loop
    // is a little less readable, but usually faster. See the distance function.
    //
    // Scene object ID: Main tube, colored inner tube or band.
    float objID = (vObjID.x<vObjID.y && vObjID.x<vObjID.z) ? 0. : (vObjID.y<vObjID.z) ? 1. : 2.;

    // Segment ID: Sorting the segments to determine the unique ID. This ID is fed
    // into a function to give various effects. Not used here.
    //float svGID = gID;
 
  // Initiate the scene color to zero.
    vec3 sc = vec3(0);
    
    
    // An object in the scene has been hit, so light it.
    if(t<FAR){
        
        // Hit position.
        vec3 sp = o + r*t;
        
        // Normal, plus edges and curvature. The latter isn't used.
        float edge = 0., crv = 1.;
        vec3 sn = nrm(sp, edge, crv, t);

        
        // Producing a gradient color based on position. Made up on the spot.
        vec3 oCol = vec3(1);
        vec3 bCol = mix(vec3(1, .1, .3).zyx, vec3(1, .5, .1).zyx, dot(sin(sp*8. - cos(sp.yzx*4. + iTime*4.)), vec3(.166)) + .5);
        //bCol = bCol.zyx; //bCol.yzx; // Other colors, if you prefer.


        
        // Color the individual objects, based on object ID.
        if(objID<.5)oCol = mix(bCol, vec3(1), .97);
        else if(objID>1.5) oCol = mix(bCol, vec3(1), .05) + bCol*2.;
        else oCol = oCol = mix(bCol, vec3(1.35), .97)*vec3(1.1, 1, .9);

        // A bit of subtle texture applied to the object.
        vec3 tx = tex3D(iChannel0, sp*2., sn);
        tx = smoothstep(.0, .5, tx)*2.;
        //
        if(objID<1.5) oCol *= tx;
        else oCol *= mix(vec3(1), tx, .5);
        
        
        // Ambient occlusion and shadows.
        float ao = cAO(sp, sn);
        float sh = shadow(sp + sn*.002, lp, 16., t); 
        

        // Point light direction vector.
        vec3 ld = lp - sp;
        float dist = max(length(ld), 0.001); // Distance.
        ld /= dist; // Using the distance to nomalize the point light direction vector.
        

        // Attenuation - based on light to surface distance.
        float atten = 3.5/(1. + dist*0.05 + dist*dist*0.05);
        
        // Diffuse light.
        float diff = max(dot(ld, sn), 0.);
        if(objID<1.5) diff = pow(diff, 4.)*2.;
        float spec = pow(max(dot( reflect(ld, sn), r), 0.0 ), 32.0);
        //float fres = clamp(1. + dot(rd, sn), 0., 1.);
        
        
        
        // Combining the above terms to produce the final color.
        sc = oCol*(diff + ao*.2) + mix(bCol.zyx, vec3(1, .7, .3), .5)*spec*4.;
        
        // Fake caustic lighting... Very fake. :)
        sc += .015/max(abs(.05 - map(sp*1.5 + sin(iTime/6.))), .01)*oCol*mix(bCol, vec3(1, .8, .5), .35);
        
        // Adding a bit of glow. It was tempting to get my money's worth, but I kept it subtle. :)
        if(objID<1.5) sc += bCol*glow*.025;
        else sc += bCol*glow*1.5;
        
        // Applying the dark edges, attenuation, shadows and ambient occlusion.
        sc *= (1. - edge*.7);
        sc *= atten*(sh + ao*.25)*ao;
        
    }
    
    
    
    // Applying some basic camera distance fog. Not to be confused with the light
    // to surface attenuation.
    float fog = 1./(1. + t*.125 + t*t*.05);
    sc = mix(vec3(0), sc, fog);//
    //sc = mix(sc, vec3(0), smoothstep(0.0, .2, t/FAR));
    
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    sc *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125);
    // Colored varation.
    //sc = mix(pow(min(vec3(1.5, 1, 1).zyx*sc, 1.), vec3(1, 3, 16).zyx), sc, 
             //pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125)*.75 + .25);
    
    
  fragColor = vec4(sqrt(max(sc, 0.)), 1);
}

void main( void ){vec4 color = vec4(0.0,0.0,0.0,1.0);mainImage( color, gl_FragCoord.xy );color.w = 1.0; FragColor = color;}  

