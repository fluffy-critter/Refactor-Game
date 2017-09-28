/* waterMask.fs

fragment shader to mask off the water by alpha threshold

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform Image mask;

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    vec4 here = Texel(txt, tc);
    float threshold = sqrt(Texel(mask, screen_coords/vec2(256.0,224.0)).r) + color.a;
    float alpha = clamp(-(here.a - threshold)*100.0, 0.0, 1.0);

    return vec4(color.rgb*here.rgb, alpha*here.a*color.a);
}

