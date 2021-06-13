// written by groverbuger for g3d
// may 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    vec4 result = projectionMatrix * viewMatrix * modelMatrix * vertexPosition;

    // for some reason models are flipped vertically when rendering to canvases
    // so we need to detect when this is being rendered to a canvas, and flip it back
    if (isCanvasEnabled) {
        result.y *= -1;
    }

    return result;
}
