/* sphereDistort.fs

Distorts a circle in a canvas to look more spherical

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform Image env;
uniform vec2 center; // center relative to the env (in texture coords)
uniform vec2 reflectSize; // size of a pixel relative to the env's texture coords

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pos = texture_coords*2.0 - vec2(1.0, 1.0);

    float r2 = dot(pos,pos);
    if (r2 > 1.) discard;

    float mask = r2 > 0.95 ? 1. - smoothstep(0.95, 1.0, r2) : 1.;
    // float mask = 1. - smoothstep(0.95, 1.0, r2);

    vec3 nrm = vec3(pos, sqrt(1. - r2));

    // distort the texture coordinate pseudo-spherically
    pos = pos*pow(r2, 0.9);

    float r4 = r2*r2;
    vec4 reflection = r4*r4*r2*Texel(env, center - reflectSize*reflect(vec3(0.,0.,1.), nrm).xy);

    return mask*(color*Texel(texture, (pos + vec2(1.0, 1.0))*0.5) + reflection);
}
