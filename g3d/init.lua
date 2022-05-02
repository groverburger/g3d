-- written by groverbuger for g3d
-- september 2021
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

g3d = {
    _VERSION     = "g3d 1.5.2",
    _DESCRIPTION = "Simple and easy 3D engine for LÖVE.",
    _URL         = "https://github.com/groverburger/g3d",
    _LICENSE     = [[
        MIT License

        Copyright (c) 2022 groverburger

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]],
    path = ...,
    shaderpath = ... .. "/g3d.vert",
}

-- the shader is what does the heavy lifting, displaying 3D meshes on your 2D monitor
g3d.shader = love.graphics.newShader(g3d.shaderpath)
g3d.newModel = require(g3d.path .. "/model")
g3d.camera = require(g3d.path .. "/camera")
g3d.collisions = require(g3d.path .. "/collisions")
g3d.loadObj = require(g3d.path .. "/objloader")
g3d.vectors = require(g3d.path .. "/vectors")
g3d.camera.updateProjectionMatrix()
g3d.camera.updateViewMatrix()

-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)

-- get rid of g3d from the global namespace and return it instead
local g3d = g3d
_G.g3d = nil
return g3d
