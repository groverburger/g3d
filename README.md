![g3d_logo](https://user-images.githubusercontent.com/19754251/91235387-502bb980-e6ea-11ea-9d12-74f762f69859.png)

groverburger's 3D engine (g3d) simplifies [LÖVE](http://love2d.org)'s 3d capabilities to be as simple as possible.
View the original forum post [here](https://love2d.org/forums/viewtopic.php?f=5&t=86350).

![pic1](demo.gif)

## Features

- 3D Model rendering
- .obj file loading
- Basic first person movement and camera controls
- Perspective and orthographic projections
- Simple, commented, and organized

## Getting Started

1. Download the latest release version
2. Add the `g3d` subfolder folder to your project
3. Add `require "g3d"` to the top of your `main.lua` file

## Games made with g3d

[Hoarder's Horrible House of Stuff](https://alesan99.itch.io/hoarders-horrible-house-of-stuff) by alesan99
![Hoarder's Gif](https://img.itch.zone/aW1hZ2UvODY2NDc3LzQ4NjYzMDcuZ2lm/original/byZGOE.gif)

[Flamerunner](https://groverburger.itch.io/flamerunner) by groverburger
![Flamerunner Gif](https://img.itch.zone/aW1nLzMzMDU0NzMuZ2lm/original/%2BM%2F78x.gif)

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

## Collision Detection

Please use the [CPML library](https://github.com/excessive/cpml) or refer to [3DreamEngine](https://github.com/3dreamengine/3DreamEngine) for their 3D collision code.

Mozilla also has a [nice article](https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection) on basic 3D collision detection.

g3d no longer offers collision detection, instead focusing only on making 3D rendering as simple as possible. Some simple integrated solution may come in a later version, however.
