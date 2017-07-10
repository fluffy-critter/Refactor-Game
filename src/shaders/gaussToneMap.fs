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
    // constants borrowed from http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
    return tonemap(Texel(txt, tc))*0.2270270270
        + tonemap(Texel(txt, tc + 1.3846153846*sampleRadius))*0.3162162162
        + tonemap(Texel(txt, tc - 1.3846153846*sampleRadius))*0.3162162162
        + tonemap(Texel(txt, tc + 3.2307692308*sampleRadius))*0.0702702703
        + tonemap(Texel(txt, tc - 3.2307692308*sampleRadius))*0.0702702703;
}

