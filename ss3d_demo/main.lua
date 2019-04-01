-- store global reference to the Engine for use in calling functions
Engine = require "engine"

function love.load()
    -- make the mouse cursor locked to the screen
    love.mouse.setRelativeMode(true)
    love.window.setTitle("ss3d 1.1 demo")

    -- create a Scene object which stores and renders Models
    -- arguments refer to the Scene's camera's canvas output size in pixels    
    Scene = Engine.newScene(love.graphics.getWidth(), love.graphics.getHeight())
    DefaultTexture = love.graphics.newImage("texture.png")
    Timer = 0

    -- define vertices to be used in the creation of a new Model object for the Scene
    local cubeVerts = {}
    -- front
    cubeVerts[#cubeVerts+1] = {0,0,0, 0,0}
    cubeVerts[#cubeVerts+1] = {1,0,0, 1,0}
    cubeVerts[#cubeVerts+1] = {0,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {1,1,0, 1,1}
    cubeVerts[#cubeVerts+1] = {0,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {1,0,0, 1,0}

    -- back
    cubeVerts[#cubeVerts+1] = {1,0,1, 1,0}
    cubeVerts[#cubeVerts+1] = {0,0,1, 0,0}
    cubeVerts[#cubeVerts+1] = {0,1,1, 0,1}
    cubeVerts[#cubeVerts+1] = {0,1,1, 0,1}
    cubeVerts[#cubeVerts+1] = {1,1,1, 1,1}
    cubeVerts[#cubeVerts+1] = {1,0,1, 1,0}

    -- right side
    cubeVerts[#cubeVerts+1] = {0,0,1, 1,0}
    cubeVerts[#cubeVerts+1] = {0,0,0, 0,0}
    cubeVerts[#cubeVerts+1] = {0,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {0,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {0,1,1, 1,1}
    cubeVerts[#cubeVerts+1] = {0,0,1, 1,0}

    -- left side
    cubeVerts[#cubeVerts+1] = {1,0,0, 0,0}
    cubeVerts[#cubeVerts+1] = {1,0,1, 1,0}
    cubeVerts[#cubeVerts+1] = {1,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {1,1,1, 1,1}
    cubeVerts[#cubeVerts+1] = {1,1,0, 0,1}
    cubeVerts[#cubeVerts+1] = {1,0,1, 1,0}

    -- top side
    cubeVerts[#cubeVerts+1] = {0,1,0}
    cubeVerts[#cubeVerts+1] = {1,1,0}
    cubeVerts[#cubeVerts+1] = {0,1,1}
    cubeVerts[#cubeVerts+1] = {1,1,1}
    cubeVerts[#cubeVerts+1] = {0,1,1}
    cubeVerts[#cubeVerts+1] = {1,1,0}

    -- bottom side
    cubeVerts[#cubeVerts+1] = {1,0,0}
    cubeVerts[#cubeVerts+1] = {0,0,0}
    cubeVerts[#cubeVerts+1] = {0,0,1}
    cubeVerts[#cubeVerts+1] = {0,0,1}
    cubeVerts[#cubeVerts+1] = {1,0,1}
    cubeVerts[#cubeVerts+1] = {1,0,0}

    -- turn the vertices into a Model with a texture
    CubeModel = Engine.newModel(cubeVerts, DefaultTexture)

    -- add the CubeModel to the Scene
    Scene.modelList[1] = CubeModel
end

function love.update(dt)
    -- make the CubeModel go in circles and rotate
    Timer = Timer + dt/2
    CubeModel:setTransform({math.cos(Timer)*3 -1, -1, math.sin(Timer)*3 -1}, {Timer, cpml.vec3.unit_y, Timer, cpml.vec3.unit_z, Timer, cpml.vec3.unit_x})

    Scene:update()
end

function love.mousemoved(x,y, dx,dy)
    -- basic first person mouselook, built into Scene object
    Scene:mouseLook(x,y, dx,dy)
end

function love.draw()
    -- render all Models in the Scene
    Scene:render()

    -- render a HUD
    Scene:renderFunction(
        function ()
            love.graphics.print("groverburger's super simple 3d engine v1.1")
        end
    )
end
