-- written by groverbuger for g3d
-- august 2020
-- MIT license

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------

Model = {
    vertexFormat = {
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
        {"VertexNormal", "float", 3},
        {"VertexColor", "byte", 4},
    },
}
Model.__index = Model

-- this returns a new instance of the Model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation, rotation, and scale are all 3d vectors and are all optional
function Model:new(given, texture, translation, rotation, scale)
    local self = setmetatable({}, Model)

    -- if given is a string, use it as a path to a .obj file
    -- otherwise given is a table, use it as a model defintion
    if type(given) == "string" then
        given = LoadObjFile(given)
    end

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = love.graphics.newImage(texture)
    end

    -- initialize my variables
    self.shader = G3DShader
    self.verts = given
    self.texture = texture
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
    self:setTransform(translation or {0,0,0}, rotation or {0,0,0}, scale or {1,1,1})

    return self
end

-- populate model's normals in model's mesh automatically
function Model:makeNormals()
    for i=1, #self.verts, 3 do
        local vp = self.verts[i]
        local v = self.verts[i+1]
        local vn = self.verts[i+2]

        local vec1 = {v[1]-vp[1], v[2]-vp[2], v[3]-vp[3]}
        local vec2 = {vn[1]-v[1], vn[2]-v[2], vn[3]-v[3]}
        local normal = NormalizeVector(CrossProduct(vec1,vec2))
        vp[6] = normal[1]
        vp[7] = normal[2]
        vp[8] = normal[3]

        v[6] = normal[1]
        v[7] = normal[2]
        v[8] = normal[3]

        vn[6] = normal[1]
        vn[7] = normal[2]
        vn[8] = normal[3]
    end
end

-- move and rotate given two 3d vectors
function Model:setTransform(translation, rotation, scale)
    self.translation = translation or {0,0,0}
    self.rotation = rotation or {0,0,0}
    self.scale = scale or {1,1,1}
    self:updateMatrix()
end

-- move given one 3d vector
function Model:setTranslation(tx,ty,tz)
    self.translation = {tx,ty,tz}
    self:updateMatrix()
end

-- rotate given one 3d vector
function Model:setRotation(rx,ry,rz)
    self.rotation = {rx,ry,rz}
    self:updateMatrix()
end

-- resize model's matrix based on a given 3d vector
function Model:setScale(sx,sy,sz)
    self.scale = {sx,sy,sz}
    self:updateMatrix()
end

-- update the model's transformation matrix
function Model:updateMatrix()
    self.matrix = GetTransformationMatrix(self.translation, self.rotation, self.scale)
end

-- draw the model
function Model:draw()
    love.graphics.setShader(self.shader)
    self.shader:send("modelMatrix", self.matrix)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end
