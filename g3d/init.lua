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

-- add the path to g3d to the global namespace
-- so submodules can know how to load their dependencies
G3D_PATH = ...

local g3d = {}

g3d.model = require(G3D_PATH .. "/model")
g3d.camera = require(G3D_PATH .. "/camera")
g3d.camera.updateProjectionMatrix()

-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)

-- get rid of G3D_PATH from the global namespace
-- so the end user doesn't have to worry about any globals
G3D_PATH = nil

return g3d
