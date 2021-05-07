// written by groverbuger for g3d
// may 2021
// MIT license

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return projectionMatrix * viewMatrix * modelMatrix * vertexPosition;
}
