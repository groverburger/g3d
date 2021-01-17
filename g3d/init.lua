-- written by groverbuger for g3d
-- january 2021
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

G3D_PATH = ...

local g3d = {}

g3d.model = require(G3D_PATH .. "/model")
g3d.camera = require(G3D_PATH .. "/camera")

-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)

return g3d
