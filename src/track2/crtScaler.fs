/* crtScaler.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Integrals computed using https://www.integral-calculator.com
*/

uniform vec2 screenSize;
uniform vec2 outputSize;

float xbrt(float x0, float x1) {
    // integral of .05sin(x) + .95 = (19x-cos(x))/20
    return (8*x1 - cos(x1) + cos(x0) - 8*x0)/9/(x1 - x0);
}

float ybrt(float y0, float y1) {
    // integral of 1 - pow(cos(y)*.5 + .5, 3) =
    // -(9sin(2x) - 4sin(x)^3 + 48sin(x) - 66x)/96
    float p0 = 9.*sin(2.*y0) - 4.*pow(sin(y0), 3.) + 48.*sin(y0) - 66.*y0;
    float p1 = 9.*sin(2.*y1) - 4.*pow(sin(y1), 3.) + 48.*sin(y1) - 66.*y1;
    return (p0 - p1)/96./(y1 - y0);
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 screen_coords) {
    // typical 14" 90s CRT was 1152 dots wide on the shadow mask; we cut this a
    // bunch because that means it's very subtle even at 4K
    const float hPitch = 1152.0/3.0;

    float dot = tc.x*hPitch;

    // phase of the left extent of the dot
    float phaseL = dot*3.14159*2;

    // phase of the right extent of the dot
    float phaseR = (tc.x + 1.0/outputSize.x)*hPitch*3.14159*2;

    vec3 maskColor = vec3(xbrt(phaseL, phaseR),
        xbrt(phaseL - 2.09, phaseR - 2.09),
        xbrt(phaseL + 2.09, phaseR + 2.09));

    // TODO: dot mask vertical pattern
    // typical dot mask had a typical aperture aspect of 9:7, meaning 1152*3/4*7/9 = 672 dots tall
    // vertical 'duty cycle' is about 85%, with an offset every other column

    // CRT scanlines
    float rowT = tc.y*screenSize.y;
    float rowB = (tc.y + 1.0/outputSize.y)*screenSize.y;
    float beamColor = ybrt(rowT*2*3.14159, rowB*2*3.14159)*.5 + .75;

    // simulate a little horizontal smearing
    vec2 ofs = vec2(0.33/screenSize.x, 0.0);
    vec4 pixelColor = 0.5*Texel(txt, tc)
        + 0.25*Texel(txt, tc + ofs)
        + 0.25*Texel(txt, tc - ofs);

    return color * vec4(pixelColor.rgb * maskColor * beamColor, 1.0);
}

