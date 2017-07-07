/* waterReflect.fs

Shader for rendering the water effect

Stores height in red channel, velocity in green (multiplied by some large factor).

*/

uniform vec2 psize; // texture coordinate step per pixel
uniform float rsize; // reflection multiplier (texcoord offset when gradient = 1)
uniform Image source; // reflection source
uniform float fresnel; // fresnel reflection term (sorta)
uniform vec4 bgColor, waveColor;

vec4 effect(vec4 color, Image water, vec2 pos, vec2 screen_coords) {
    vec2 dx = vec2(psize.x, 0);
    vec2 dy = vec2(0, psize.y);
    vec2 gradient = vec2(Texel(water, pos + dx*0.5).r - Texel(water, pos - dx*0.5).r,
                         Texel(water, pos + dy*0.5).r - Texel(water, pos - dy*0.5).r);

    return color*mix(bgColor + waveColor*Texel(water, pos).r,
        Texel(source, pos + gradient*psize*rsize),
        min(1.0, fresnel*dot(gradient, gradient)));
}
