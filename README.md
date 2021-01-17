![g3d_logo](https://user-images.githubusercontent.com/19754251/91235387-502bb980-e6ea-11ea-9d12-74f762f69859.png)

groverburger's 3D engine (g3d) simplifies [LÖVE](http://love2d.org)'s 3d capabilities to be as simple as possible.<br/>
View the original forum post [here](https://love2d.org/forums/viewtopic.php?f=5&t=86350).

![pic1](demo.gif)

## Features

- 3D Model rendering
- .obj file loading
- Basic first person movement and camera controls
- Perspective and orthographic projections
- Simple, commented, and organized

## Getting Started

1. Download the latest release version.
2. Add the `g3d` subfolder folder to your project.
3. Add `require "g3d"` to the top of your `main.lua` file.

For more information, check out the [g3d wiki](https://github.com/groverburger/g3d/wiki)!

## Games made with g3d

[Hoarder's Horrible House of Stuff](https://alesan99.itch.io/hoarders-horrible-house-of-stuff) by alesan99<br/>
![Hoarder's Gif](https://img.itch.zone/aW1hZ2UvODY2NDc3LzQ4NjYzMDcuZ2lm/original/byZGOE.gif)

[Flamerunner](https://groverburger.itch.io/flamerunner) by groverburger (that's me!)<br/>
![Flamerunner Gif](https://img.itch.zone/aW1nLzMzMDU0NzMuZ2lm/original/%2BM%2F78x.gif)

## Demo Code

The entire `main.lua` file for the Earth and Moon demo is under 30 lines, as shown here:
```lua
-- written by groverbuger for g3d
-- january 2021
-- MIT license

g3d = require "g3d"

function love.load()
    Earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {0,0,4}, nil, {-1,1,1})
    Moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", nil, nil, {-0.5,0.5,0.5})
    Background = g3d.newModel("assets/sphere.obj", "assets/starfield.png")
    Background:setScale(500)
    Timer = 0
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    Timer = Timer + dt
    Moon:setTranslation(math.cos(Timer)*5, 0, math.sin(Timer)*5 +4)
    Moon:setRotation(0,-1*Timer,0)
    g3d.camera.firstPersonMovement(dt)
end

function love.draw()
    Earth:draw()
    Moon:draw()
    Background:draw()
end
```

## Additional Help and FAQ 

Check out the [g3d wiki](https://github.com/groverburger/g3d/wiki)!
