# G3D

groverburger's 3D engine (g3d) simplifies love2d's 3d capabilities to be as simple as possible.

![pic1](alakazam.gif)

### Features:
- 3D Model rendering
- .obj file loading
- Simple collision handling
- Basic first person movement controls

### Installation
Add the g3d folder to your project.

### Usage

The entire main.lua file for the demo shown is 28 lines, as shown here:
```lua
-- written by groverbuger for g3d
-- august 2020
-- MIT license

require "g3d"

function love.load()
    Alakazam = Model:new("assets/alakazam.obj", "assets/texture.png", {0,2,5})
    Skybox = Model:new("assets/skybox.obj", "assets/skybox.png", {0,0,0}, {0,0,0}, {500,500,500})
    Floor = Model:new("assets/floor.obj", "assets/stone.jpg", {0,2,5}, {0,0,0}, {8,1,8})
    Timer = 0
end

function love.mousemoved(x,y, dx,dy)
    FirstPersonCameraLook(dx,dy)
end

function love.update(dt)
    Timer = Timer + dt
    Alakazam:setRotation(0,Timer,math.pi)
    FirstPersonCameraMovement(dt)
end

function love.draw()
    Skybox:draw()
    Alakazam:draw()
    Floor:draw()
end
```

- create a model with Model:new(obj, texture) passing in the .obj and texture
- translate and rotate the model with Model:setTranslation(x,y,z) and Model:setRotation(x,y,z)
- move and rotate the camera with SetCamera(x,y,z, direction,pitch) or SetCameraAndLookAt(x,y,z, xAt,yAt,zAt)
- use basic first person movement with FirstPersonCameraMovement(dt) and FirstPersonCameraLook(dx,dy)

For more information, check out the model.lua and camera.lua files.
The code is commented and designed to be readable.
