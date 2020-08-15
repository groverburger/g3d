-- written by groverbuger for g3d
-- august 2020
-- MIT license

function InitializeCamera()
    ----------------------------------------------------------------------------------------------------
    -- initialize the 3d shader
    ----------------------------------------------------------------------------------------------------

    CameraShader = love.graphics.newShader [[
        uniform mat4 projectionMatrix;
        uniform mat4 modelMatrix;
        uniform mat4 viewMatrix;

        #ifdef VERTEX
            vec4 position(mat4 transform_projection, vec4 vertex_position)
            {
                return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
            }
        #endif

        #ifdef PIXEL
            vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
            {
                vec4 texcolor = Texel(tex, texcoord);
                if (texcolor.a == 0.0) { discard; }
                return vec4(texcolor);
            }
        #endif
    ]]

    ----------------------------------------------------------------------------------------------------
    -- initialize the shader with a basic camera
    ----------------------------------------------------------------------------------------------------

    Camera = {
        fov = math.pi/2,
        nearClip = 0.01,
        farClip = 1000,
        aspectRatio = 1,

        position = {0,0,0},
        direction = 0,
        pitch = 0,
        down = {0,1,0},
    }

    -- create the projection matrix from the camera
    -- and send it to the shader
    CameraShader:send("projectionMatrix", GetProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio))
    
    CameraLookInDirection(0, 0)

    -- so that far polygons don't overlap near polygons
    love.graphics.setDepthMode("lequal", true)
end

function CameraLookInDirection(direction, pitch)
    Camera.direction = direction
    Camera.pitch = pitch or 0

    local sign = math.cos(Camera.pitch)
    if sign > 0 then
        sign = 1
    elseif sign < 0 then
        sign = -1
    else
        sign = 0
    end
    local cosPitch = sign*math.max(math.abs(math.cos(Camera.pitch)), 0.001)
    local target = {Camera.position[1]+math.sin(Camera.direction)*cosPitch, Camera.position[2]-math.sin(Camera.pitch), Camera.position[3]+math.cos(Camera.direction)*cosPitch}

    CameraShader:send("viewMatrix", GetViewMatrix(Camera.position, target, Camera.down))
end
