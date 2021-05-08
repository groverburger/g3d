// written by groverbuger for g3d
// may 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return projectionMatrix * viewMatrix * modelMatrix * vertexPosition;
}
