/* outlineFont.fs


(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.


Uses a BMFont-encoded font; expected channel configuration:

alpha - mask including outline
red - glyph

*/

uniform vec4 outlineColor; // the color of the outline

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    vec4 px = Texel(txt,tc);
    return mix(outlineColor, color, px.r)*px.a;
}
