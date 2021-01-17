-- written by groverbuger for g3d
-- january 2021
-- MIT license

local shader = require(G3D_PATH .. "/shader")
local matrices = require(G3D_PATH .. "/matrices")

----------------------------------------------------------------------------------------------------
-- define the camera singleton
----------------------------------------------------------------------------------------------------

local camera = {
    fov = math.pi/2,
    nearClip = 0.01,
    farClip = 1000,
    aspectRatio = love.graphics.getWidth()/love.graphics.getHeight(),
    position = {0,0,0},
    target = {0,0,0},
    down = {0,-1,0},
}

-- private variables used only for the first person camera functions
local fpsController = {
    direction = 0,
    pitch = 0
}

-- give the camera a point to look from and a point to look towards
function camera.lookAt(x,y,z, xAt,yAt,zAt)
    camera.position[1] = x
    camera.position[2] = y
    camera.position[3] = z
    camera.target[1] = xAt
    camera.target[2] = yAt
    camera.target[3] = zAt

    -- TODO: update fpsController's direction and pitch here

    -- update the camera in the shader
    camera.updateViewMatrix()
end

-- move and rotate the camera, given a point and a direction and a pitch (vertical direction)
function camera.lookTowards(x,y,z, directionTowards,pitchTowards)
    camera.position[1] = x
    camera.position[2] = y
    camera.position[3] = z

    fpsController.direction = directionTowards or fpsController.direction
    fpsController.pitch = pitchTowards or fpsController.pitch

    -- convert the direction and pitch into a target point
    local sign = math.cos(fpsController.pitch)
    if sign > 0 then
        sign = 1
    elseif sign < 0 then
        sign = -1
    else
        sign = 0
    end
    local cosPitch = sign*math.max(math.abs(math.cos(fpsController.pitch)), 0.001)
    camera.target[1] = camera.position[1]+math.sin(fpsController.direction)*cosPitch
    camera.target[2] = camera.position[2]-math.sin(fpsController.pitch)
    camera.target[3] = camera.position[3]+math.cos(fpsController.direction)*cosPitch

    -- update the camera in the shader
    camera.updateViewMatrix()
end

-- recreate the camera's view matrix from its current values
-- and send the matrix to the shader specified, or the default shader
function camera.updateViewMatrix(shaderGiven)
    (shaderGiven or shader):send("viewMatrix", matrices.getViewMatrix(camera.position, camera.target, camera.down))
end

-- recreate the camera's projection matrix from its current values
-- and send the matrix to the shader specified, or the default shader
function camera.updateProjectionMatrix(shaderGiven)
    (shaderGiven or shader):send("projectionMatrix", matrices.getProjectionMatrix(camera.fov, camera.nearClip, camera.farClip, camera.aspectRatio))
end

-- simple first person camera movement with WASD
-- put this local function in your love.update to use, passing in dt
function camera.firstPersonMovement(dt)
    -- collect inputs
    local mx,my = 0,0
    local cameraMoved = false
    if love.keyboard.isDown("w") then
        my = my - 1
    end
    if love.keyboard.isDown("a") then
        mx = mx - 1
    end
    if love.keyboard.isDown("s") then
        my = my + 1
    end
    if love.keyboard.isDown("d") then
        mx = mx + 1
    end
    if love.keyboard.isDown("space") then
        camera.position[2] = camera.position[2] - 0.15*dt*60
        cameraMoved = true
    end
    if love.keyboard.isDown("lshift") then
        camera.position[2] = camera.position[2] + 0.15*dt*60
        cameraMoved = true
    end

    -- add camera's direction and movement direction
    -- then move in the resulting direction
    if mx ~= 0 or my ~= 0 then
        local angle = math.atan2(my,mx)
        local speed = 0.15
        local dx,dz = math.cos(fpsController.direction + angle)*speed*dt*60, math.sin(fpsController.direction + angle + math.pi)*speed*dt*60

        camera.position[1] = camera.position[1] + dx
        camera.position[3] = camera.position[3] + dz
        cameraMoved = true
    end

    if cameraMoved then
        camera.lookTowards(camera.position[1],camera.position[2],camera.position[3], fpsController.direction,fpsController.pitch)
    end
end

-- best served with firstPersoncameraMovement()
-- use this in your love.mousemoved function, passing in the movements
function camera.firstPersonLook(dx,dy)
    love.mouse.setRelativeMode(true)
    local sensitivity = 1/300
    fpsController.direction = fpsController.direction + dx*sensitivity
    fpsController.pitch = math.max(math.min(fpsController.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    camera.lookTowards(camera.position[1],camera.position[2],camera.position[3], fpsController.direction,fpsController.pitch)
end

return camera
