/* windDistort.fs

Distort the monk texture based on wind speed

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 windAmount;
uniform float phase;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float mag = Texel(texture, tc + vec2(0.5,0.0)).r *
        Texel(texture, vec2(tc.x + 0.5, fract(tc.y + phase))).g;

    return color * Texel(texture, tc + windAmount*mag);
}
