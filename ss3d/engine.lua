-- Super Simple 3D Engine v1.2
-- groverburger 2019

local function TransposeMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.transpose(m, mat)
end
local function InvertMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.invert(m, mat)
end
local function CrossProduct(v1,v2)
    local a = {x = v1[1], y = v1[2], z = v1[3]}
    local b = {x = v2[1], y = v2[2], z = v2[3]}

    local x, y, z
    x = a.y * (b.z or 0) - (a.z or 0) * b.y
    y = (a.z or 0) * b.x - a.x * (b.z or 0)
    z = a.x * b.y - a.y * b.x
    return { x, y, z }
end
local function VectorLength(x2,y2,z2)
    local x1,y1,z1 = 0,0,0
    return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5
end
local function UnitVectorOf(vector)
    local ab1 = math.abs(vector[1])
    local ab2 = math.abs(vector[2])
    local ab3 = math.abs(vector[3])
    local max = VectorLength(ab1, ab2, ab3)
    if max == 0 then max = 1 end

    local ret = {vector[1]/max, vector[2]/max, vector[3]/max}
    return ret
end

local engine = {}

function engine.loadObj(objPath)
    local obj = ObjReader.load(objPath)
	local faces = {}
	local verts = {}
	
	for i,v in pairs(obj.v) do
			table.insert(verts, {v.x,v.y,v.z})
	end
	for i,v in pairs(obj.f) do
			table.insert(faces, {verts[v[1].v][1], verts[v[1].v][2], verts[v[1].v][3], obj.vt[v[1].vt].u, obj.vt[v[1].vt].v})
			table.insert(faces, {verts[v[2].v][1], verts[v[2].v][2], verts[v[2].v][3], obj.vt[v[2].vt].u, obj.vt[v[2].vt].v})
			table.insert(faces, {verts[v[3].v][1], verts[v[3].v][2], verts[v[3].v][3], obj.vt[v[3].vt].u, obj.vt[v[3].vt].v})
	end
	return faces
end

-- create a new Model object
-- given a table of verts for example: { {0,0,0}, {0,1,0}, {0,0,1} }
-- each vert is its own table that contains three coordinate numbers, and may contain 2 extra numbers as uv coordinates
-- another example, this with uvs: { {0,0,0, 0,0}, {0,1,0, 1,0}, {0,0,1, 0,1} }
-- polygons are automatically created with three consecutive verts
function engine.newModel(verts, texture)
    local m = {}

    -- default values if no arguments are given
    local format = {
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
        {"VertexNormal", "float", 3},
    }

    assert(verts ~= nil, "Invalid vertices recieved in newModel")

    if texture == nil then
        m.texture = love.graphics.newCanvas(1,1)
        love.graphics.setCanvas(m.texture)
        love.graphics.clear(0,0,0)
        love.graphics.setCanvas()
    else
        m.texture = texture
    end

    -- translate verts by given coords
    for i=1, #verts do
        -- if not given uv coordinates, put in random ones
        if #verts[i] < 5 then
            verts[i][4] = love.math.random()
            verts[i][5] = love.math.random()
        end

        -- if not given normals, figure it out
        if #verts[i] < 8 then
            local polyindex = math.floor((i-1)/3)
            local polyfirst = polyindex*3 +1
            local polysecond = polyindex*3 +2
            local polythird = polyindex*3 +3

            local sn1 = {}
            sn1[1] = verts[polythird][1] - verts[polysecond][1]
            sn1[2] = verts[polythird][2] - verts[polysecond][2]
            sn1[3] = verts[polythird][3] - verts[polysecond][3]

            local sn2 = {}
            sn2[1] = verts[polysecond][1] - verts[polyfirst][1]
            sn2[2] = verts[polysecond][2] - verts[polyfirst][2]
            sn2[3] = verts[polysecond][3] - verts[polyfirst][3]

            local cross = UnitVectorOf(CrossProduct(sn1,sn2))

            verts[i][6] = cross[1]
            verts[i][7] = cross[2]
            verts[i][8] = cross[3]
        end
    end

    -- define the Model object's properties
    m.mesh = nil
    if #verts > 0 then
        m.mesh = love.graphics.newMesh(format, verts, "triangles")
        m.mesh:setTexture(m.texture)
    end
    m.format = format
    m.verts = verts
    m.transform = TransposeMatrix(cpml.mat4.identity())
    m.visible = true
    m.wireframe = false
    m.culling = false

    m.setVerts = function (self, verts)
        if #verts > 0 then
            self.mesh = love.graphics.newMesh(self.format, verts, "triangles")
            self.mesh:setTexture(self.texture)
        end
        self.verts = verts
    end

    -- translate and rotate the Model
    m.setTransform = function (self, coords, rotations, scale)
        if angle == nil then
            angle = 0
            axis = cpml.vec3.unit_y
        end
        self.transform = cpml.mat4.identity()
        self.transform:translate(self.transform, cpml.vec3(unpack(coords)))
        if rotations ~= nil then
            for i=1, #rotations, 2 do
                self.transform:rotate(self.transform, rotations[i],rotations[i+1])
            end
        end
        if scale ~= nil then
            self.transform:scale(self.transform, cpml.vec3(unpack(scale)))
        end
        self.transform = TransposeMatrix(self.transform)
    end

    -- returns a list of the verts this Model contains
    m.getVerts = function (self)
        local ret = {}
        for i=1, #self.verts do
            ret[#ret+1] = {self.verts[i][1], self.verts[i][2], self.verts[i][3]}
        end

        return ret
    end

    -- prints a list of the verts this Model contains
    m.printVerts = function (self)
        local verts = self:getVerts()
        for i=1, #verts do
            print(verts[i][1], verts[i][2], verts[i][3])
            if i%3 == 0 then
                print("---")
            end
        end
    end

    -- set a texture to this Model
    m.setTexture = function (self, tex)
        self.mesh:setTexture(tex)
    end

    return m
end

-- create a new Scene object with given canvas output size
function engine.newScene(renderWidth,renderHeight)
	love.graphics.setDepthMode("lequal", true)
    local scene = {}

    -- define the shaders used in rendering the scene
    scene.threeShader = love.graphics.newShader[[
        uniform mat4 view;
        uniform mat4 model_matrix;
        uniform mat4 model_matrix_inverse;
        uniform float ambientLight;
        uniform vec3 ambientVector;

        varying mat4 modelView;
        varying mat4 modelViewProjection;
        varying vec3 normal;
        varying vec3 vposition;

        #ifdef VERTEX
            attribute vec4 VertexNormal;

            vec4 position(mat4 transform_projection, vec4 vertex_position) {
                modelView = view * model_matrix;
                modelViewProjection = view * model_matrix * transform_projection;

                normal = vec3(model_matrix_inverse * vec4(VertexNormal));
                vposition = vec3(model_matrix * vertex_position);

                return view * model_matrix * vertex_position;
            }
        #endif

        #ifdef PIXEL
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
                vec4 texturecolor = Texel(texture, texture_coords);

                // if the alpha here is zero just don't draw anything here
                // otherwise alpha values of zero will render as black pixels
                if (texturecolor.a == 0.0)
                {
                    discard;
                }

                float light = max(dot(normalize(ambientVector), normal), 0);
                texturecolor.rgb *= max(light, ambientLight);

                return color*texturecolor;
            }
        #endif
    ]]


    scene.renderWidth = renderWidth
    scene.renderHeight = renderHeight

    -- create a canvas that will store the rendered 3d scene
    scene.threeCanvas = love.graphics.newCanvas(renderWidth, renderHeight)

    -- a list of all models in the scene
    scene.modelList = {}

    scene.fov = 90
    scene.nearClip = 0.001
    scene.farClip = 10000
    scene.camera = {
        pos = cpml.vec3(0,0,0),
        angle = cpml.vec3(0,0,0),
        perspective = TransposeMatrix(cpml.mat4.from_perspective(scene.fov, renderWidth/renderHeight, scene.nearClip, scene.farClip)),
    }

    scene.ambientLight = 0.25
    scene.ambientVector = {0,1,0}

    -- returns a reference to the model
    scene.addModel = function (self, model)
        table.insert(self.modelList, model)
        return model
    end

    -- finds and removes model, returns boolean if successful
    scene.removeModel = function (self, model)
        local i = 1

        while i<=#(self.modelList) do
            if self.modelList[i] == model then
                table.remove(self.modelList, i)
                return true
            else
                i=i+1
            end
        end

        return false
    end

    scene.changeCamera = function (self, fov, near, far)
        self.fov = fov
        self.nearClip = near
        self.farClip = far
        self.camera.perspective = TransposeMatrix(cpml.mat4.from_perspective(self.fov, self.renderWidth/self.renderHeight, self.nearClip, self.farClip))
    end

    -- resize output canvas to given dimensions
    scene.resize = function (self, renderWidth, renderHeight)
        self.renderWidth = renderWidth
        self.renderHeight = renderHeight
        self.threeCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
        self.twoCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
        self.camera.perspective = TransposeMatrix(cpml.mat4.from_perspective(self.fov, renderWidth/renderHeight, self.nearClip, self.farClip))
    end

    -- renders the models in the scene to the threeCanvas
    -- will draw threeCanvas if drawArg is not given or is true (use if you want to scale the game canvas to window)
    scene.render = function (self, drawArg)
        love.graphics.setColor(1,1,1)
        love.graphics.setCanvas({self.threeCanvas, depth=true})
        love.graphics.clear(0,0,0,0)
        love.graphics.setShader(self.threeShader)

        -- compile camera data into usable view to send to threeShader
        local Camera = self.camera
        local camTransform = cpml.mat4()
        camTransform:rotate(camTransform, Camera.angle.y, cpml.vec3.unit_x)
        camTransform:rotate(camTransform, Camera.angle.x, cpml.vec3.unit_y)
        camTransform:rotate(camTransform, Camera.angle.z, cpml.vec3.unit_z)
        camTransform:translate(camTransform, Camera.pos*-1)
        self.threeShader:send("view", Camera.perspective * TransposeMatrix(camTransform))
        self.threeShader:send("ambientLight", self.ambientLight)
        self.threeShader:send("ambientVector", self.ambientVector)

        -- go through all models in modelList and draw them
        for i=1, #self.modelList do
            local model = self.modelList[i]
            if model ~= nil and model.visible and #model.verts > 0 then
                self.threeShader:send("model_matrix", model.transform)
                self.threeShader:send("model_matrix_inverse", TransposeMatrix(InvertMatrix(model.transform)))

                love.graphics.setWireframe(model.wireframe)
                if model.culling then
                    love.graphics.setMeshCullMode("back")
                end

                love.graphics.draw(model.mesh, -self.renderWidth/2, -self.renderHeight/2)

                love.graphics.setMeshCullMode("none")
                love.graphics.setWireframe(false)
            end
        end

        love.graphics.setShader()
        love.graphics.setCanvas()

        love.graphics.setColor(1,1,1)
        if drawArg == nil or drawArg == true then
            love.graphics.draw(self.threeCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,-1, self.renderWidth/2, self.renderHeight/2)
        end
    end

    -- useful if mouse relativeMode is enabled
    -- useful to call from love.mousemoved
    -- a simple first person mouse look function
    scene.mouseLook = function (self, x, y, dx, dy)
        local Camera = self.camera
        Camera.angle.x = Camera.angle.x + math.rad(dx * 0.5)
        Camera.angle.y = math.max(math.min(Camera.angle.y + math.rad(dy * 0.5), math.pi/2), -1*math.pi/2)
    end

    return scene
end

-- useful functions
function engine.scaleVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]*sx
        this[2] = this[2]*sy
        this[3] = this[3]*sz
    end

    return verts
end
function engine.moveVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]+sx
        this[2] = this[2]+sy
        this[3] = this[3]+sz
    end

    return verts
end

return engine

