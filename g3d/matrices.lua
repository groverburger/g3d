-- written by groverbuger for g3d
-- january 2021
-- MIT license

local vectors = require(G3D_PATH .. "/vectors")

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

local matrices = {}

-- returns a transformation matrix
-- translation and rotation are 3d vectors
function matrices.getTransformationMatrix(translation, rotation, scale)
    local ret = matrices.getIdentityMatrix()

    -- translations
    ret[4] = translation[1]
    ret[8] = translation[2]
    ret[12] = translation[3]

    -- rotations
    -- x
    local rx = matrices.getIdentityMatrix()
    rx[6] = math.cos(rotation[1])
    rx[7] = -1*math.sin(rotation[1])
    rx[10] = math.sin(rotation[1])
    rx[11] = math.cos(rotation[1])
    ret = matrices.multiply(ret, rx)

    -- y
    local ry = matrices.getIdentityMatrix()
    ry[1] = math.cos(rotation[2])
    ry[3] = math.sin(rotation[2])
    ry[9] = -1*math.sin(rotation[2])
    ry[11] = math.cos(rotation[2])
    ret = matrices.multiply(ret, ry)

    -- z
    local rz = matrices.getIdentityMatrix()
    rz[1] = math.cos(rotation[3])
    rz[2] = -1*math.sin(rotation[3])
    rz[5] = math.sin(rotation[3])
    rz[6] = math.cos(rotation[3])
    ret = matrices.multiply(ret, rz)

    -- scale
    local sm = matrices.getIdentityMatrix()
    sm[1] = scale[1]
    sm[6] = scale[2]
    sm[11] = scale[3]
    ret = matrices.multiply(ret, sm)

    return ret
end

-- returns a standard projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrices.getProjectionMatrix(fov, near, far, aspectRatio)
    local top = near * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    return {
        2*near/(right-left), 0, (right+left)/(right-left), 0,
        0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0,
        0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near),
        0, 0, -1, 0
    }
end

-- returns an orthographic projection matrix
-- (things farther away are the same size as things closer)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrices.getOrthographicMatrix(fov, size, near, far, aspectRatio)
    local top = size * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    return {
        2/(right-left), 0, 0, -1*(right+left)/(right-left),
        0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom),
        0, 0, -2/(far-near), -(far+near)/(far-near),
        0, 0, 0, 1
    }
end

-- returns a view matrix
-- eye, target, and down are all 3d vectors
function matrices.getViewMatrix(eye, target, down)
    local z = vectors.normalizeVector({eye[1] - target[1], eye[2] - target[2], eye[3] - target[3]})
    local x = vectors.normalizeVector(vectors.crossProduct(down, z))
    local y = vectors.crossProduct(z, x)

    return {
        x[1], x[2], x[3], -1*vectors.dotProduct(x, eye),
        y[1], y[2], y[3], -1*vectors.dotProduct(y, eye),
        z[1], z[2], z[3], -1*vectors.dotProduct(z, eye),
        0, 0, 0, 1,
    }
end

----------------------------------------------------------------------------------------------------
-- basic matrix functions
----------------------------------------------------------------------------------------------------
-- matrices are just 16 numbers in table, representing a 4x4 matrix
-- an identity matrix is defined as {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}

function matrices.getIdentityMatrix()
    return {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
end

-- i find rows and columns confusing, so i use coordinate pairs instead
-- this returns a value of a matrix at a specific coordinate
function matrices.getMatrixValueAt(matrix, x,y)
    return matrix[x + (y-1)*4]
end

-- return the matrix that results from the two given matrices multiplied together
function matrices.multiply(a,b)
    local ret = {0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0}

    local i = 1
    for y=1, 4 do
        for x=1, 4 do
            ret[i] = ret[i] + matrices.getMatrixValueAt(a,1,y)*matrices.getMatrixValueAt(b,x,1)
            ret[i] = ret[i] + matrices.getMatrixValueAt(a,2,y)*matrices.getMatrixValueAt(b,x,2)
            ret[i] = ret[i] + matrices.getMatrixValueAt(a,3,y)*matrices.getMatrixValueAt(b,x,3)
            ret[i] = ret[i] + matrices.getMatrixValueAt(a,4,y)*matrices.getMatrixValueAt(b,x,4)
            i = i + 1
        end
    end

    return ret
end

return matrices
