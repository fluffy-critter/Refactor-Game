/* gaussBlur.fs

references: http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 sampleRadius; // the radius for the kernel (1 pixel size in the filter direction)

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    // used ptri.py to compute the offsets for a radius of 25
    // offsets = [0, 1.416666666666667, 3.3333333333333335, 5.25]
    // weights = [0.16160033427347748, 0.2344092760890003, 0.08790347853337512, 0.01608691110414708]
    return color*((Texel(txt, tc))*0.16160033427347748
        + (Texel(txt, tc + 1.416666666666667*sampleRadius))*0.2344092760890003
        + (Texel(txt, tc - 1.416666666666667*sampleRadius))*0.2344092760890003
        + (Texel(txt, tc + 3.3333333333333335*sampleRadius))*0.08790347853337512
        + (Texel(txt, tc - 3.3333333333333335*sampleRadius))*0.08790347853337512
        + (Texel(txt, tc + 5.25*sampleRadius))*0.01608691110414708
        + (Texel(txt, tc - 5.25*sampleRadius))*0.01608691110414708)/(
            0.16160033427347748 + 2.0*0.2344092760890003 + 2.0*0.08790347853337512 + 2.0*0.01608691110414708
        );
}

