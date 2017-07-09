/* sphereDistort.fs

Distorts a circle in a canvas to look more spherical
*/

uniform float gamma; // how much to distort by

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pos = texture_coords*2.0 - vec2(1.0, 1.0);

    float r = min(1.0, length(pos));

    pos = pos*pow(r, gamma);

    pos = (pos + vec2(1.0, 1.0))*0.5;
    return color*Texel(texture, pos);
}
