/* sphereDistort.fs

Distorts a circle in a canvas to look more spherical

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform float gamma; // how much to distort by
uniform Image env;
uniform vec2 center; // center relative to the env (in texture coords)
uniform vec2 reflectSize; // size of a pixel relative to the env's texture coords

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pos = texture_coords*2.0 - vec2(1.0, 1.0);

    float r2 = dot(pos,pos);
    vec4 reflection = vec4(0.,0.,0.,0.);

    if (r2 <= 1.) {
        vec3 nrm = vec3(pos, sqrt(1. - min(1.,r2)));

        pos = pos*pow(r2, gamma);

        reflection = pow(r2, 5.)*Texel(env, center - reflectSize*reflect(vec3(0.,0.,1.), nrm).xy);
    }

    pos = (pos + vec2(1.0, 1.0))*0.5;
    return color*Texel(texture, pos) + reflection;
}
