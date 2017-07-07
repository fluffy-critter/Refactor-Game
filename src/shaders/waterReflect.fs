/* waterReflect.fs

Shader for rendering the water effect

Stores height in red channel, velocity in green (multiplied by some large factor)

*/

uniform vec2 psize; // texture coordinate step per pixel
uniform float rsize; // reflection multiplier (texcoord offset when gradient = 1)
uniform Image source; // reflection source
uniform float fresnel; // fresnel reflection term (sorta)

vec4 effect(vec4 color, Image texture, vec2 pos, vec2 screen_coords) {
    vec2 dx = vec2(psize.x, 0);
    vec2 dy = vec2(0, psize.y);
    vec2 gradient = vec2(Texel(texture, pos + dx*0.5).r - Texel(texture, pos - dx*0.5).r,
                         Texel(texture, pos + dy*0.5).r - Texel(texture, pos - dy*0.5).r);

    return Texel(source, pos + gradient*psize*rsize)*fresnel*length(gradient);
}
