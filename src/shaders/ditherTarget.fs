uniform Image error;
uniform float levels;

uniform float getValue, getError;

vec4 effect(vec4 color, Image canvas, vec2 tc, vec2 screen_coords) {
    vec4 total = Texel(error, tc)/levels +  Texel(canvas, tc);

    vec4 outValue = floor(total*levels)/levels;
    vec4 outError = (total - outValue)*levels;

    return outError*getError + outValue*getValue;
}
