/* crtScaler.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 screenSize;
uniform vec2 outputSize;

float brt(float phaseL, float phaseR) {
    // integral of .05sin(x) + .95 = (19x-cos(x))/20
    return (19*phaseR - cos(phaseR) + cos(phaseL) - 19*phaseL)/20;
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    // typical 14" 90s CRT was 1152 dots wide on the shadow mask; we cut this a
    // bunch because that means it's very subtle even at 4K
    const float hPitch = 1152.0/4.0;

    float dot = tc.x*hPitch;

    // phase of the left extent of the dot
    float phaseL = dot*3.14159*2;

    // phase of the right extent of the dot
    float phaseR = (tc.x + 1.0/outputSize.x)*hPitch*3.14159*2;

    vec3 maskColor = vec3(brt(phaseL, phaseR), brt(phaseL - 2.09, phaseR - 2.09), brt(phaseL + 2.09, phaseR + 2.09))*1.2 / (phaseR - phaseL);

    // TODO: dot mask vertical pattern
    // typical dot mask had a typical aperture aspect of 9:7, meaning 1152*3/4*7/9 = 672 dots tall
    // vertical 'duty cycle' is about 85%, with an offset every other column

    // CRT scanlines
    float row = tc.y*screenSize.y;
    float yRowPos = fract(row) - 0.5;
    float yBrt = sqrt(1.0 - yRowPos*yRowPos*2.0);

    // simulate a little horizontal smearing
    vec2 ofs = vec2(0.25/screenSize.x, 0.0);
    vec4 pixelColor = 0.5*Texel(txt, tc)
        + 0.25*Texel(txt, tc + ofs)
        + 0.25*Texel(txt, tc - ofs);

    return color * vec4(pixelColor.rgb * maskColor * yBrt, 1.0);
}

