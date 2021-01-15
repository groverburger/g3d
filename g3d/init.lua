-- written by groverbuger for g3d
-- august 2020
-- MIT license

--[[
         __       __     
       /'__`\    /\ \    
   __ /\_\L\ \   \_\ \   
 /'_ `\/_/_\_<_  /'_` \  
/\ \L\ \/\ \L\ \/\ \L\ \ 
\ \____ \ \____/\ \___,_\
 \/___L\ \/___/  \/__,_ /
   /\____/               
   \_/__/                
--]]

----------------------------------------------------------------------------------------------------
-- set up the basic 3D shader
----------------------------------------------------------------------------------------------------
-- the shader that projects 3D meshes onto the screen

G3DShader = love.graphics.newShader [[
    uniform mat4 projectionMatrix;
    uniform mat4 modelMatrix;
    uniform mat4 viewMatrix;

    varying vec4 vertexColor;

    #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vertexColor = VertexColor;
            return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
        }
    #endif

    #ifdef PIXEL
        vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
        {
            vec4 texcolor = Texel(tex, texcoord);
            if (texcolor.a == 0.0) { discard; }
            return vec4(texcolor)*color*vertexColor;
        }
    #endif
]]

----------------------------------------------------------------------------------------------------
-- load in all the required files
----------------------------------------------------------------------------------------------------

require(... .. "/matrices")
require(... .. "/objloader")
require(... .. "/model")
require(... .. "/camera")

----------------------------------------------------------------------------------------------------
-- set up the basic camera
----------------------------------------------------------------------------------------------------

Camera = {
    fov = math.pi/2,
    nearClip = 0.01,
    farClip = 1000,
    aspectRatio = love.graphics.getWidth()/love.graphics.getHeight(),
    position = {0,0,0},
    direction = 0,
    pitch = 0,
    down = {0,-1,0},
}

-- create the projection matrix from the camera and send it to the shader
G3DShader:send("projectionMatrix", GetProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio))

-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)
