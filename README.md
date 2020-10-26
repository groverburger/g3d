![g3d_logo](https://user-images.githubusercontent.com/19754251/91235387-502bb980-e6ea-11ea-9d12-74f762f69859.png)

groverburger's 3D engine (g3d) simplifies [LÖVE](http://love2d.org)'s 3d capabilities to be as simple as possible.

![pic1](demo.gif)

## Features

- 3D Model rendering
- .obj file loading
- Basic first person movement and camera controls
- Perspective and orthographic projections
- Functions for simple collision handling
- Simple, commented, and organized

## Installation

Add the `g3d` subfolder folder to your project, and require it in `main.lua`.

## Usage

The entire `main.lua` file for the demo shown is under 30 lines, as shown here:
```lua
-- written by groverbuger for g3d
-- october 2020
-- MIT license

require "g3d"

function love.load()
    Earth = Model:new("assets/sphere.obj", "assets/earth.png", {0,0,4}, nil, {-1,1,1})
    Moon = Model:new("assets/sphere.obj", "assets/moon.png", {5,0,4}, nil, {-0.5,0.5,0.5})
    Background = Model:new("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
    Timer = 0
end

function love.mousemoved(x,y, dx,dy)
    FirstPersonCameraLook(dx,dy)
end

function love.update(dt)
    Timer = Timer + dt
    Moon:setTranslation(math.cos(Timer)*5, 0, math.sin(Timer)*5 +4)
    Moon:setRotation(0,-1*Timer,0)
    FirstPersonCameraMovement(dt)
end

function love.draw()
    Earth:draw()
    Moon:draw()
    Background:draw()
end
```

## Functionality

- Create `Model`s with `Model:new(obj, texture)` passing in a path to a .obj file and a LÖVE image file
- Translate and rotate the `Model` with `Model:setTranslation(x,y,z)` and `Model:setRotation(x,y,z)`
- Move and rotate the `Camera` with `SetCamera(x,y,z, direction,pitch)` or `SetCameraAndLookAt(x,y,z, xAt,yAt,zAt)`
- Use basic first person movement with `FirstPersonCameraMovement(dt)` and `FirstPersonCameraLook(dx,dy)`

For more information, check out the `model.lua` and `camera.lua` files.
