// written by groverbuger for g3d
// may 2021
// MIT license

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
    vec4 texcolor = Texel(tex, texcoord);
    if (texcolor.a == 0.0) discard;
    return texcolor * VaryingColor;
}
