/* waterRipple.fs

Shader for incrementing the water ripple effect

Stores height in red channel, velocity in green (multiplied by some large factor)

*/

uniform vec2 psize; // texture coordinate step per pixel
uniform float dt; // time increment
uniform float damp; // damping factor

vec4 effect(vec4 color, Image texture, vec2 pos, vec2 screen_coords) {
    vec4 here = Texel(texture, pos);
    float z = here.r*2.0 - 1.0;
    float v = (here.g*2.0 - 1.0)/30.0;

    vec2 dx = vec2(psize.x, 0);
    vec2 dy = vec2(0, psize.y);

    // target height (weighted local average of neighbors)
    float tz = (Texel(texture, pos + dx).r
        + Texel(texture, pos + dy).r
        + Texel(texture, pos - dx).r
        + Texel(texture, pos - dy).r
        + Texel(texture, pos + (dx + dy)*0.707).r
        + Texel(texture, pos + (dx - dy)*0.707).r
        + Texel(texture, pos + (-dx + dy)*0.707).r
        + Texel(texture, pos + (-dx - dy)*0.707).r
        + 0.5*damp)/(4.0 + damp) - 1.0;

    // v += (tz - z)*dt*viscosity;
    // z = (z + v*dt)*pow(damp, dt);
    // return vec4(z*0.5 + 0.5, v*0.5/30.0 + 0.5, 0, 0);

    return vec4(tz*0.5 + 0.5, v, 0, 0);
}
