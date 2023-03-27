
local newMatrix = require(g3d.path .. ".matrices")
local g3d = g3d -- save a reference to g3d in case the user makes it non-global

local camera = {}
camera.__index = camera

function camera.current()
    return camera._current
end

function camera.setCurrent(to)
    camera._current = to

    to:updateProjectionMatrix()
    to:updateViewMatrix()
end

function camera.newCamera()
    local self = setmetatable({}, camera)
    
    self.fov = math.pi/2
    self.nearClip = 0.01
    self.farClip = 1000
    self.aspectRatio = love.graphics.getWidth()/love.graphics.getHeight()
    self.position = {0,0,0}
    self.target = {1,0,0}
    self.up = {0,0,1}
    self.speed = 1

    --FPS controller properties.
    self.direction = 0
    self.pitch = 0

    self.viewMatrix = newMatrix()
    self.projectionMatrix = newMatrix()

    -- set the global camera to this camera.
    if(not camera.current()) then
        camera.setCurrent(self)
    end

    return self
end

----------------------------------------------------------------------------------------------------
-- define the camera singleton
----------------------------------------------------------------------------------------------------

function camera:getDirectionPitch()
    return self.direction, self.pitch
end

-- convenient function to return the camera's normalized look vector
function camera:getLookVector()
    local vx = self.target[1] - self.position[1]
    local vy = self.target[2] - self.position[2]
    local vz = self.target[3] - self.position[3]
    local length = math.sqrt(vx^2 + vy^2 + vz^2)

    -- make sure not to divide by 0
    if length > 0 then
        return vx/length, vy/length, vz/length
    end
    return vx,vy,vz
end

-- give the camera a point to look from and a point to look towards
function camera:lookAt(x,y,z, xAt,yAt,zAt)
    self.position[1] = x
    self.position[2] = y
    self.position[3] = z
    self.target[1] = xAt
    self.target[2] = yAt
    self.target[3] = zAt

    -- update the fpsController's direction and pitch based on lookAt
    local dx,dy,dz = self:getLookVector()
    self.direction = math.pi/2 - math.atan2(dz, dx)
    self.pitch = math.atan2(dy, math.sqrt(dx^2 + dz^2))

    -- update the camera in the shader
    self:updateViewMatrix()
end

-- move and rotate the camera, given a point and a direction and a pitch (vertical direction)
function camera:lookInDirection(x,y,z, directionTowards,pitchTowards)
    self.position[1] = x or self.position[1]
    self.position[2] = y or self.position[2]
    self.position[3] = z or self.position[3]

    self.direction = directionTowards or self.direction
    self.pitch = pitchTowards or self.pitch

    -- turn the cos of the pitch into a sign value, either 1, -1, or 0
    local sign = math.cos(self.pitch)
    sign = (sign > 0 and 1) or (sign < 0 and -1) or 0

    -- don't let cosPitch ever hit 0, because weird camera glitches will happen
    local cosPitch = sign*math.max(math.abs(math.cos(self.pitch)), 0.00001)

    -- convert the direction and pitch into a target point
    self.target[1] = self.position[1]+math.cos(self.direction)*cosPitch
    self.target[2] = self.position[2]+math.sin(self.direction)*cosPitch
    self.target[3] = self.position[3]+math.sin(self.pitch)

    -- update the camera in the shader
    self:updateViewMatrix()
end

-- recreate the camera's view matrix from its current values
function camera:updateViewMatrix()
    self.viewMatrix:setViewMatrix(self.position, self.target, self.up)
end

-- retrieve the view matrix
function camera:getViewMatrix()
    return self.viewMatrix
end

-- recreate the camera's projection matrix from its current values
function camera:updateProjectionMatrix()
    self.projectionMatrix:setProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
end

-- retreive the projectionMatrix
function camera:getProjectionMatrix()
    return self.projectionMatrix;
end

-- recreate the camera's orthographic projection matrix from its current values
function camera:updateOrthographicMatrix(size)
    self.projectionMatrix:setOrthographicMatrix(self.fov, size or 5, self.nearClip, self.farClip, self.aspectRatio)
end

-- simple first person camera movement with WASD
-- put this local function in your love.update to use, passing in dt
function camera:firstPersonMovement(dt)
    -- collect inputs
    local moveX, moveY = 0, 0
    local cameraMoved = false
    local speed = self.speed or 1
    if love.keyboard.isDown "w" then moveX = moveX + 1 end
    if love.keyboard.isDown "a" then moveY = moveY + 1 end
    if love.keyboard.isDown "s" then moveX = moveX - 1 end
    if love.keyboard.isDown "d" then moveY = moveY - 1 end
    if love.keyboard.isDown "space" then
        self.position[3] = self.position[3] + speed*dt
        cameraMoved = true
    end
    if love.keyboard.isDown "lshift" then
        self.position[3] = self.position[3] - speed*dt
        cameraMoved = true
    end

    -- do some trigonometry on the inputs to make movement relative to camera's direction
    -- also to make the player not move faster in diagonal directions
    if moveX ~= 0 or moveY ~= 0 then
        local angle = math.atan2(moveY, moveX)
        self.position[1] = self.position[1] + math.cos(self.direction + angle) * speed * dt
        self.position[2] = self.position[2] + math.sin(self.direction + angle) * speed * dt
        cameraMoved = true
    end

    -- update the camera's in the shader
    -- only if the camera moved, for a slight performance benefit
    if cameraMoved then
        self:lookInDirection()
    end
    return cameraMoved;
end

-- use this in your love.mousemoved function, passing in the movements
function camera:firstPersonLook(dx,dy)
    -- capture the mouse
    -- love.mouse.setRelativeMode(true)

    local sensitivity = 1/300
    self.direction = self.direction - dx*sensitivity
    self.pitch = math.max(math.min(self.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    self:lookInDirection(self.position[1],self.position[2],self.position[3], self.direction,self.pitch)
end

-- create one camera to function as a default static camera
camera.newCamera();

return camera;