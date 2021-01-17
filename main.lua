-- written by groverbuger for g3d
-- january 2021
-- MIT license

g3d = require "g3d"

function love.load()
    Earth = g3d.model.new("assets/sphere.obj", "assets/earth.png", {0,0,4}, nil, {-1,1,1})
    Moon = g3d.model.new("assets/sphere.obj", "assets/moon.png", {5,0,4}, nil, {-0.5,0.5,0.5})
    Background = g3d.model.new("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
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
