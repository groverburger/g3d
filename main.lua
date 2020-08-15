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
