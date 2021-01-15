-- written by groverbuger for g3d
-- august 2020
-- MIT license

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

-- returns a transformation matrix
-- translation and rotation are 3d vectors
function GetTransformationMatrix(translation, rotation, scale)
    local ret = IdentityMatrix()

    -- translations
    ret[4] = translation[1]
    ret[8] = translation[2]
    ret[12] = translation[3]

    -- rotations
    -- x
    local rx = IdentityMatrix()
    rx[6] = math.cos(rotation[1])
    rx[7] = -1*math.sin(rotation[1])
    rx[10] = math.sin(rotation[1])
    rx[11] = math.cos(rotation[1])
    ret = MatrixMult(ret, rx)

    -- y
    local ry = IdentityMatrix()
    ry[1] = math.cos(rotation[2])
    ry[3] = math.sin(rotation[2])
    ry[9] = -math.sin(rotation[2])
    ry[11] = math.cos(rotation[2])
    ret = MatrixMult(ret, ry)

    -- z
    local rz = IdentityMatrix()
    rz[1] = math.cos(rotation[3])
    rz[2] = -math.sin(rotation[3])
    rz[5] = math.sin(rotation[3])
    rz[6] = math.cos(rotation[3])
    ret = MatrixMult(ret, rz)

    -- scale
    local sm = IdentityMatrix()
    sm[1] = scale[1]
    sm[6] = scale[2]
    sm[11] = scale[3]
    ret = MatrixMult(ret, sm)

    return ret
end

-- returns a standard projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function GetProjectionMatrix(fov, near, far, aspectRatio)
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
function GetOrthoMatrix(fov, size, near, far, aspectRatio)
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
function GetViewMatrix(eye, target, down)
    local z = NormalizeVector({eye[1] - target[1], eye[2] - target[2], eye[3] - target[3]})
    local x = NormalizeVector(CrossProduct(down, z))
    local y = CrossProduct(z, x)

    return {
        x[1], x[2], x[3], -1*DotProduct(x, eye),
        y[1], y[2], y[3], -1*DotProduct(y, eye),
        z[1], z[2], z[3], -1*DotProduct(z, eye),
        0, 0, 0, 1,
    }
end

----------------------------------------------------------------------------------------------------
-- basic vector functions
----------------------------------------------------------------------------------------------------
-- vectors are just 3 numbers in table, defined like {1,0,0}

function NormalizeVector(vector)
    local dist = math.sqrt(vector[1]^2 + vector[2]^2 + vector[3]^2)
    return {
        vector[1]/dist,
        vector[2]/dist,
        vector[3]/dist,
    }
end

function SubtractVector(v1, v2)
    return {v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]}
end

function DotProduct(a,b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

function CrossProduct(a,b)
    return {
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1],
    }
end

----------------------------------------------------------------------------------------------------
-- basic matrix functions
----------------------------------------------------------------------------------------------------
-- matrices are just 16 numbers in table, representing a 4x4 matrix
-- an identity matrix is defined as {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}

function IdentityMatrix()
    return {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
end

-- i find rows and columns confusing, so i use coordinate pairs instead
-- this returns a value of a matrix at a specific coordinate
function GetMatrixXY(matrix, x,y)
    return matrix[x + (y-1)*4]
end

-- return the matrix that results from the two given matrices multiplied together
function MatrixMult(a,b)
    local ret = {0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0}

    local i = 1
    for y=1, 4 do
        for x=1, 4 do
            ret[i] = ret[i] + GetMatrixXY(a,1,y)*GetMatrixXY(b,x,1)
            ret[i] = ret[i] + GetMatrixXY(a,2,y)*GetMatrixXY(b,x,2)
            ret[i] = ret[i] + GetMatrixXY(a,3,y)*GetMatrixXY(b,x,3)
            ret[i] = ret[i] + GetMatrixXY(a,4,y)*GetMatrixXY(b,x,4)
            i = i + 1
        end
    end

    return ret
end

-- returns a transpose of the given matrix
function TransposeMatrix(m)
    return {
        GetMatrixXY(m, 1,1), GetMatrixXY(m, 1,2), GetMatrixXY(m, 1,3), GetMatrixXY(m, 1,4),
        GetMatrixXY(m, 2,1), GetMatrixXY(m, 2,2), GetMatrixXY(m, 2,3), GetMatrixXY(m, 2,4),
        GetMatrixXY(m, 3,1), GetMatrixXY(m, 3,2), GetMatrixXY(m, 3,3), GetMatrixXY(m, 3,4),
        GetMatrixXY(m, 4,1), GetMatrixXY(m, 4,2), GetMatrixXY(m, 4,3), GetMatrixXY(m, 4,4),
    }
end
