/* waterRipple.fs

Shader for incrementing the water ripple effect

Stores height in red channel, velocity in green (multiplied by some large factor)

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 psize; // texture coordinate step per pixel
uniform float dt; // time increment
uniform float damp; // damping factor
uniform float fluidity; // inverse of viscosity

vec4 effect(vec4 color, Image water, vec2 pos, vec2 screen_coords) {
    vec4 here = Texel(water, pos);
    float z = here.r;
    float v = here.g;

    vec2 dx = vec2(psize.x, 0);
    vec2 dy = vec2(0, psize.y);

    // target height (average of neighbors)
    float tz = (Texel(water, pos + dx).r
        + Texel(water, pos + dy).r
        + Texel(water, pos - dx).r
        + Texel(water, pos - dy).r
        + Texel(water, pos + (dx + dy)*0.707).r
        + Texel(water, pos + (dx - dy)*0.707).r
        + Texel(water, pos + (-dx + dy)*0.707).r
        + Texel(water, pos + (-dx - dy)*0.707).r)/8.0;

    v += (tz - z)*dt*fluidity;
    z += v*dt;
    v = v*pow(damp, dt);

    return vec4(z, v, 0, 0);
}
