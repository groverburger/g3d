-- written by groverbuger for g3d
-- may 2021
-- MIT license

local g3d = require "g3d"
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {0,0,4})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {5,0,4}, nil, {0.5,0.5,0.5})
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
local timer = 0

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    timer = timer + dt
    moon:setTranslation(math.cos(timer)*5, 0, math.sin(timer)*5 +4)
    moon:setRotation(0, math.pi - timer, 0)
    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end
end

function love.draw()
    earth:draw()
    moon:draw()
    background:draw()
end
