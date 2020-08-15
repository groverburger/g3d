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

    shader = nil,
}
Model.__index = Model

-- this returns a new instance of the Model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation and rotation are 3d vectors and are optional
function Model:new(given, texture, translation, rotation)
    local self = setmetatable({}, Model)

    -- if given is a string, use it as a path to a .obj file
    -- otherwise given is a table, use it as a model defintion
    if type(given) == "string" then
        given = LoadObjFile(given)
    end

    if not Model.shader then
        ----------------------------------------------------------------------------------------------------
        -- initialize the 3d shader
        ----------------------------------------------------------------------------------------------------

        Model.shader = love.graphics.newShader [[
            uniform mat4 projectionMatrix;
            uniform mat4 modelMatrix;
            uniform mat4 viewMatrix;

            #ifdef VERTEX
                vec4 position(mat4 transform_projection, vec4 vertex_position)
                {
                    return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
                }
            #endif

            #ifdef PIXEL
                vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
                {
                    vec4 texcolor = Texel(tex, texcoord);
                    if (texcolor.a == 0.0) { discard; }
                    return vec4(texcolor);
                }
            #endif
        ]]

        ----------------------------------------------------------------------------------------------------
        -- initialize the shader with a basic camera
        ----------------------------------------------------------------------------------------------------

        -- this says that the camera has
            -- a FOV of 90 degrees (pi/2 in radians)
            -- a near clip plane of 0.01 units (very close to the camera)
            -- a far clip plane of 1000 units (very far from the camera)
        Model.shader:send("projectionMatrix", GetProjectionMatrix(math.pi/2, 0.01, 1000, 1))
        -- this says that the camera is
            -- at 0,0,0
            -- looking at 1,0,0 (down the x-axis)
            -- oriented so that negative y is upwards
        Model.shader:send("viewMatrix", GetViewMatrix({0,0,0}, {1,0,0}, {0,1,0}))

        -- so that far polygons don't overlap near polygons
        love.graphics.setDepthMode("lequal", true)
    end

    -- initialize my variables
    self.verts = given
    self.texture = texture
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
    self:setTransform(translation or {0,0,0}, rotation or {0,0,0})

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

-- resize model based on a given 3d vector
function Model:scale(scaleVector)
    for i,v in pairs(self.verts) do
        v[1] = v[1] * scaleVector[1]
        v[2] = v[2] * scaleVector[2]
        v[3] = v[3] * scaleVector[3]
    end
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
end

-- move and rotate given two 3d vectors
function Model:setTransform(translation, rotation)
    self.translation = translation or {0,0,0}
    self.rotation = rotation or {0,0,0}
    self.matrix = GetTransformationMatrix(self.translation, self.rotation)
end

-- move given one 3d vector
function Model:setTranslation(tx,ty,tz)
    self.translation = {tx,ty,tz}
    self.matrix = GetTransformationMatrix(self.translation, self.rotation)
end

-- rotate given one 3d vector
function Model:setRotation(rx,ry,rz)
    self.rotation = {rx,ry,rz}
    self.matrix = GetTransformationMatrix(self.translation, self.rotation)
end

-- draw the model
function Model:draw()
    love.graphics.setShader(self.shader)
    self.shader:send("modelMatrix", self.matrix)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end

-- check if a vector has collided with this model
-- takes two 3d vectors as arguments, sourcePoint and directionVector
-- returns length of vector from sourcePoint to collisionPoint
-- and returns the collisionPoint
-- length will be nil if no collision was found
-- this function is useful for building game physics
function Model:vectorIntersection(sourcePoint, directionVector)
    local length = nil
    local where = {}

    for v=1, #self.verts, 3 do
        if dotProd(self.verts[v][6],self.verts[v][7],self.verts[v][8], directionVector[1],directionVector[2],directionVector[3]) < 0 then

            local this, w1,w2,w3 = FastRayTriangle(sourcePoint[1],sourcePoint[2],sourcePoint[3],
                directionVector[1],directionVector[2],directionVector[3],
                self.verts[v][1] + self.translation[1],
                self.verts[v][2] + self.translation[2],
                self.verts[v][3] + self.translation[3],
                self.verts[v+1][1] + self.translation[1],
                self.verts[v+1][2] + self.translation[2],
                self.verts[v+1][3] + self.translation[3],
                self.verts[v+2][1] + self.translation[1],
                self.verts[v+2][2] + self.translation[2],
                self.verts[v+2][3] + self.translation[3]
            )

            if this then
                if not length or length > this then
                    length = this
                    where = {w1,w2,w3}
                end
            end
        end
    end

    return length, where
end
