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
