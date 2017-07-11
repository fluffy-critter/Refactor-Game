/* gaussToneMap.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 sampleRadius; // the radius for the kernel (1 pixel size in the filter direction)
uniform vec4 lowCut; // low cut color on the input stage
uniform float gamma; // gamma on input stage post-cut


vec4 tonemap(vec4 color) {
    return pow(max(vec4(0.,0.,0.,0.), color - lowCut)/(vec4(1.,1.,1.,1.) - lowCut), vec4(gamma,gamma,gamma,gamma));
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    // used ptri.py to comute the offsets for a radius of 25
    // offsets = [0, 1.416666666666667, 3.3333333333333335, 5.25]
    // weights = [0.16160033427347748, 0.2344092760890003, 0.08790347853337512, 0.01608691110414708]
    return tonemap(Texel(txt, tc))*0.16160033427347748
        + tonemap(Texel(txt, tc + 1.416666666666667*sampleRadius))*0.2344092760890003
        + tonemap(Texel(txt, tc - 1.416666666666667*sampleRadius))*0.2344092760890003
        + tonemap(Texel(txt, tc + 3.3333333333333335*sampleRadius))*0.08790347853337512
        + tonemap(Texel(txt, tc - 3.3333333333333335*sampleRadius))*0.08790347853337512
        + tonemap(Texel(txt, tc + 5.25*sampleRadius))*0.01608691110414708
        + tonemap(Texel(txt, tc - 5.25*sampleRadius))*0.01608691110414708;
}

