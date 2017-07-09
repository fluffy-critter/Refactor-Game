/* gaussToneMap.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 sampleRadius; // the radius for the kernel (1 pixel size in the filter direction)
uniform vec4 lowCut; // low cut color on the input stage
uniform float gamma; // gamma on input stage post-cut

// borrowed from http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
uniform float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );
uniform float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );

vec4 tonemap(vec4 color) {
    return pow(max(vec4(0.,0.,0.,0.), color - lowCut)/(vec4(1.,1.,1.,1.) - lowCut), vec4(gamma,gamma,gamma,gamma));
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    return tonemap(Texel(txt, tc))*weight[0]
        + tonemap(Texel(txt, tc + offset[1]*sampleRadius))*weight[1]
        + tonemap(Texel(txt, tc - offset[1]*sampleRadius))*weight[1]
        + tonemap(Texel(txt, tc + offset[2]*sampleRadius))*weight[2]
        + tonemap(Texel(txt, tc - offset[2]*sampleRadius))*weight[2];
}

