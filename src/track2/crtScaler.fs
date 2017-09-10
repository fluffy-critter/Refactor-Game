/* crtScaler.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 screenSize;

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    float phase = tc.x*screenSize.x*3.14159*2.2;
    vec4 scanColor = vec4(sin(phase)*0.05 + 0.95, sin(phase - 2.09)*0.05 + 0.95, sin(phase + 2.09)*0.05 + 0.95, 1.0);

    float row = tc.y*screenSize.y;
    float yRowPos = fract(row) - 0.5;
    float yBrt = sqrt(1.0 - yRowPos*yRowPos*2.0);
    return color * vec4(((0.9*Texel(txt, tc) + 0.3*Texel(txt, tc - vec2(0.5/screenSize.x, 0))) * scanColor * yBrt).rgb, 1.0);
}

