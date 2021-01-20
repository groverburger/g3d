-- written by groverbuger for g3d
-- october 2020
-- MIT license

require "g3d"

function love.load()
    Earth = Model:new("assets/sphere.obj", "assets/earth.png", {0,0,4})
    Moon = Model:new("assets/sphere.obj", "assets/moon.png", {5,0,4}, nil, {0.5,0.5,0.5})
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
