# G3D

groverburger's 3D engine (g3d) simplifies love2d's 3d capabilities to be as simple as possible.

![pic1](alakazam.gif)

### Features:
- 3D Model rendering
- .obj file loading
- Simple collision handling

### Installation
Add the g3d folder to your project.

### Usage

The entire main.lua file for the demo shown is 21 lines, as shown here:
```lua
-- written by groverbuger
-- august 2020
-- MIT license

require "g3d"

function love.load()
    Texture = love.graphics.newImage("assets/texture.png")
    Alakazam = Model:new("assets/alakazam.obj", Texture)
    Alakazam:setTranslation(5,-2,0)
    Timer = 0
end

function love.update(dt)
    Timer = Timer + dt
    Alakazam:setRotation(0,Timer,0)
end

function love.draw()
    Alakazam:draw()
end
```

For more information, check out the model.lua file.
The code is fully commented and designed to be readable.
