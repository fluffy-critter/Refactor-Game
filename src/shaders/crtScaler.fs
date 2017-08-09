/* crtScaler.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 screenSize;

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    float phase = tc.x*screenSize.x*3.14159*2.2;
    vec4 scanColor = vec4(sin(phase)*0.15 + 0.85, sin(phase - 2.09)*0.15 + 0.85, sin(phase + 2.09)*0.15 + 0.85, 1.0);

    float row = tc.y*screenSize.y;
    return color * vec4((Texel(txt, tc) * scanColor * sqrt(max(0.2, fract(row)*1.5))).rgb, 1.0);
}

