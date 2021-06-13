-- written by groverbuger for g3d
-- may 2021
-- MIT license

local newMatrix = require(g3d.path .. "/matrices")
local g3d = g3d -- save a reference to g3d in case the user makes it non-global

----------------------------------------------------------------------------------------------------
-- define the camera singleton
----------------------------------------------------------------------------------------------------

local camera = {
    fov = math.pi/2,
    nearClip = 0.01,
    farClip = 1000,
    aspectRatio = love.graphics.getWidth()/love.graphics.getHeight(),
    position = {0,0,0},
    target = {0,0,1},
    up = {0,-1,0},

    viewMatrix = newMatrix(),
    projectionMatrix = newMatrix(),
}

-- private variables used only for the first person camera functions
local fpsController = {
    direction = 0,
    pitch = 0
}

-- read-only variables, can't be set by the end user
function camera.getDirectionPitch()
    return fpsController.direction, fpsController.pitch
end

-- convenient function to return the camera's normalized look vector
function camera.getLookVector()
    local vx = camera.target[1] - camera.position[1]
    local vy = camera.target[2] - camera.position[2]
    local vz = camera.target[3] - camera.position[3]
    local length = math.sqrt(vx^2 + vy^2 + vz^2)

    -- make sure not to divide by 0
    if length > 0 then
        return vx/length, vy/length, vz/length
    end
    return vx,vy,vz
end

-- give the camera a point to look from and a point to look towards
function camera.lookAt(x,y,z, xAt,yAt,zAt)
    camera.position[1] = x
    camera.position[2] = y
    camera.position[3] = z
    camera.target[1] = xAt
    camera.target[2] = yAt
    camera.target[3] = zAt

    -- update the fpsController's direction and pitch based on lookAt
    -- thanks 4v0v!
    local dx,dy,dz = camera.getLookVector()
    fpsController.direction = math.pi/2 - math.atan2(dz, dx)
    fpsController.pitch = -math.atan2(dy, math.sqrt(dx^2 + dz^2))

    -- update the camera in the shader
    camera.updateViewMatrix()
end

-- move and rotate the camera, given a point and a direction and a pitch (vertical direction)
function camera.lookInDirection(x,y,z, directionTowards,pitchTowards)
    camera.position[1] = x or camera.position[1]
    camera.position[2] = y or camera.position[2]
    camera.position[3] = z or camera.position[3]

    fpsController.direction = directionTowards or fpsController.direction
    fpsController.pitch = pitchTowards or fpsController.pitch

    -- convert the direction and pitch into a target point

    -- turn the cos of the pitch into a sign value, either 1, -1, or 0
    local sign = math.cos(fpsController.pitch)
    sign = (sign > 0 and 1) or (sign < 0 and -1) or 0

    -- don't let cosPitch ever hit 0, because weird camera glitches will happen
    local cosPitch = sign*math.max(math.abs(math.cos(fpsController.pitch)), 0.00001)

    camera.target[1] = camera.position[1]+math.sin(fpsController.direction)*cosPitch
    camera.target[2] = camera.position[2]-math.sin(fpsController.pitch)
    camera.target[3] = camera.position[3]+math.cos(fpsController.direction)*cosPitch

    -- update the camera in the shader
    camera.updateViewMatrix()
end

-- recreate the camera's view matrix from its current values
-- and send the matrix to the shader specified, or the default shader
function camera.updateViewMatrix(shaderGiven)
    local shader = shaderGiven or g3d.shader
    camera.viewMatrix:setViewMatrix(camera.position, camera.target, camera.up)
    shader:send("viewMatrix", camera.viewMatrix)
end

-- recreate the camera's projection matrix from its current values
-- and send the matrix to the shader specified, or the default shader
function camera.updateProjectionMatrix(shaderGiven)
    local shader = shaderGiven or g3d.shader
    camera.projectionMatrix:setProjectionMatrix(camera.fov, camera.nearClip, camera.farClip, camera.aspectRatio)
    shader:send("projectionMatrix", camera.projectionMatrix)
end

-- recreate the camera's orthographic projection matrix from its current values
-- and send the matrix to the shader specified, or the default shader
function camera.updateOrthographicMatrix(shaderGiven, size)
    local shader = shaderGiven or g3d.shader
    camera.projectionMatrix:setOrthographicMatrix(camera.fov, size or 5, camera.nearClip, camera.farClip, camera.aspectRatio)
    shader:send("projectionMatrix", camera.projectionMatrix)
end

-- simple first person camera movement with WASD
-- put this local function in your love.update to use, passing in dt
function camera.firstPersonMovement(dt)
    -- collect inputs
    local moveX, moveY = 0, 0
    local cameraMoved = false
    local speed = 9
    if love.keyboard.isDown "w" then moveY = moveY - 1 end
    if love.keyboard.isDown "a" then moveX = moveX - 1 end
    if love.keyboard.isDown "s" then moveY = moveY + 1 end
    if love.keyboard.isDown "d" then moveX = moveX + 1 end
    if love.keyboard.isDown "space" then
        camera.position[2] = camera.position[2] - speed*dt
        cameraMoved = true
    end
    if love.keyboard.isDown "lshift" then
        camera.position[2] = camera.position[2] + speed*dt
        cameraMoved = true
    end

    -- do some trigonometry on the inputs to make movement relative to camera's direction
    -- also to make the player not move faster in diagonal directions
    if moveX ~= 0 or moveY ~= 0 then
        local angle = math.atan2(moveY, moveX)
        camera.position[1] = camera.position[1] + math.cos(fpsController.direction + angle) * speed * dt
        camera.position[3] = camera.position[3] + math.sin(fpsController.direction + angle + math.pi) * speed * dt
        cameraMoved = true
    end

    -- update the camera's in the shader
    -- only if the camera moved, for a slight performance benefit
    if cameraMoved then
        camera.lookInDirection()
    end
end

-- use this in your love.mousemoved function, passing in the movements
function camera.firstPersonLook(dx,dy)
    -- capture the mouse
    love.mouse.setRelativeMode(true)

    local sensitivity = 1/300
    fpsController.direction = fpsController.direction + dx*sensitivity
    fpsController.pitch = math.max(math.min(fpsController.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    camera.lookInDirection(camera.position[1],camera.position[2],camera.position[3], fpsController.direction,fpsController.pitch)
end

return camera
