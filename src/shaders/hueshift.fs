/* hueshift.fs

Hue/saturation shift shader. (Use setColor() to further attenuate the brightness or whatever.)

See https://beesbuzz.biz/code/hsv_color_transforms.php for an explanation of the math.

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
*/

uniform vec2 basis; // transform basis; {saturation*cos(theta), saturation*sin(theta)}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    float rotU = basis.x;
    float rotV = basis.y;

    vec4 here = Texel(texture, texture_coords);

    return vec4(
        (
              (.299+.701*rotU+.168*rotV)*here.r
            + (.587-.587*rotU+.330*rotV)*here.g
            + (.114-.114*rotU-.497*rotV)*here.b
        ),
        (
              (.299-.299*rotU-.328*rotV)*here.r
            + (.587+.413*rotU+.035*rotV)*here.g
            + (.114-.114*rotU+.292*rotV)*here.b
        ),
        (
              (.299-.300*rotU+1.25*rotV)*here.r
            + (.587-.588*rotU-1.05*rotV)*here.g
            + (.114+.886*rotU-.203*rotV)*here.b
        ),
        here.a)*color;
}
