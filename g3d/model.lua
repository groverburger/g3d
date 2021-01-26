-- written by groverbuger for g3d
-- january 2021
-- MIT license

local vectors = require(G3D_PATH .. "/vectors")
local matrices = require(G3D_PATH .. "/matrices")
local loadObjFile = require(G3D_PATH .. "/objloader")
local collisions = require(G3D_PATH .. "/collisions")

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------

local model = {}
model.__index = model

-- define some default properties that every model should inherit
-- that being the standard vertexFormat and basic 3D shader
model.vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexColor", "byte", 4},
}
model.shader = require(G3D_PATH .. "/shader")

-- give the model some collision functions
-- so it can act like a collider
model.generateAABB = collisions.generateAABB
model.isIntersectionAABB = collisions.isIntersectionAABB
model.isPointInsideAABB = collisions.isPointInsideAABB
model.isRayCollision = collisions.isRayCollision

-- this returns a new instance of the model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation, rotation, and scale are all 3d vectors and are all optional
local function newModel(given, texture, translation, rotation, scale)
    local self = setmetatable({}, model)

    -- if given is a string, use it as a path to a .obj file
    -- otherwise given is a table, use it as a model defintion
    if type(given) == "string" then
        given = loadObjFile(given)
    end
    assert(given and type(given) == "table", "Corrupt vertices given to newModel")

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = love.graphics.newImage(texture)
    end

    -- initialize my variables
    self.verts = given
    self.texture = texture
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
    self:setTransform(translation or {0,0,0}, rotation or {0,0,0}, scale or {1,1,1})
    self:generateAABB()

    return self
end

-- populate model's normals in model's mesh automatically
-- if true is passed in, then the normals are all flipped
function model:makeNormals(isFlipped)
    for i=1, #self.verts, 3 do
        local vp = self.verts[i]
        local v = self.verts[i+1]
        local vn = self.verts[i+2]

        local vec1 = {v[1]-vp[1], v[2]-vp[2], v[3]-vp[3]}
        local vec2 = {vn[1]-v[1], vn[2]-v[2], vn[3]-v[3]}
        local normal = vectors.normalizeVector(vectors.crossProduct(vec1,vec2))
        local flippage = isFlipped and -1 or 1

        vp[6] = normal[1] * flippage
        vp[7] = normal[2] * flippage
        vp[8] = normal[3] * flippage

        v[6] = normal[1] * flippage
        v[7] = normal[2] * flippage
        v[8] = normal[3] * flippage

        vn[6] = normal[1] * flippage
        vn[7] = normal[2] * flippage
        vn[8] = normal[3] * flippage
    end
end

-- move and rotate given two 3d vectors
function model:setTransform(translation, rotation, scale)
    self.translation = translation or self.translation
    self.rotation = rotation or self.rotation
    self.scale = scale or self.scale
    self:updateMatrix()
end

-- move given one 3d vector
function model:setTranslation(tx,ty,tz)
    self.translation[1] = tx
    self.translation[2] = ty
    self.translation[3] = tz
    self:updateMatrix()
end

-- rotate given one 3d vector
function model:setRotation(rx,ry,rz)
    self.rotation[1] = rx
    self.rotation[2] = ry
    self.rotation[3] = rz
    self:updateMatrix()
end

-- resize model's matrix based on a given 3d vector
function model:setScale(sx,sy,sz)
    self.scale[1] = sx
    self.scale[2] = sy or sx
    self.scale[3] = sz or sx
    self:updateMatrix()
end

-- update the model's transformation matrix
function model:updateMatrix()
    self.matrix = matrices.getTransformationMatrix(self.translation, self.rotation, self.scale)
end

-- draw the model
function model:draw()
    love.graphics.setShader(self.shader)
    self.shader:send("modelMatrix", self.matrix)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end

return newModel
