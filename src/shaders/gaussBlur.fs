/* gaussBlur.fs

references:

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 sampleRadius; // the radius for the kernel (1 pixel size in the filter direction)

// borrowed from http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
uniform float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );
uniform float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    return (Texel(txt, tc))*weight[0]
        + (Texel(txt, tc + offset[1]*sampleRadius))*weight[1]
        + (Texel(txt, tc - offset[1]*sampleRadius))*weight[1]
        + (Texel(txt, tc + offset[2]*sampleRadius))*weight[2]
        + (Texel(txt, tc - offset[2]*sampleRadius))*weight[2];
}

