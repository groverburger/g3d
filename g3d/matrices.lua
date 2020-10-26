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

----------------------------------------------------------------------------------------------------
-- detect collisions between a model and a vector
----------------------------------------------------------------------------------------------------
-- these functions are used for the Model:vectorIntersection function

local function subtractVector(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end
local function crossProd(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end
local function dotProd(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end
local DBL_EPSILON = 2.2204460492503131e-16

-- taken and modified for efficiency from Cirno's Perfect Math Library
-- using just numbers and not vector tables for efficiency
function FastRayTriangle(p1,p2,p3, d1,d2,d3, t11,t12,t13,t21,t22,t23,t31,t32,t33)
    local e11,e12,e13 = subtractVector(t21,t22,t23, t11,t12,t13)
    local e21,e22,e23 = subtractVector(t31,t32,t33, t11,t12,t13)
    local h1,h2,h3 = crossProd(d1,d2,d3, e21,e22,e23)
    local a = dotProd(h1,h2,h3, e11,e12,e13)

    -- if a is too close to 0, ray does not intersect triangle
    if math.abs(a) <= DBL_EPSILON then
        return false
    end

    local f = 1 / a
    local s1,s2,s3 = subtractVector(p1,p2,p3, t11,t12,t13)
    local u = dotProd(s1,s2,s3, h1,h2,h3) * f

    -- ray does not intersect triangle
    if u < 0 or u > 1 then
        return false
    end

    local q1,q2,q3 = crossProd(s1,s2,s3, e11,e12,e13)
    local v = dotProd(d1,d2,d3, q1,q2,q3) * f

    -- ray does not intersect triangle
    if v < 0 or u + v > 1 then
        return false
    end

    -- at this stage we can compute t to find out where
    -- the intersection point is on the line
    local t = dotProd(q1,q2,q3, e21,e22,e23) * f

    -- return position of intersection and distance from ray origin
    if t >= DBL_EPSILON then
        return t, p1 + d1*t,p2 + d2*t,p3 + d3*t
    end

    -- ray does not intersect triangle
    return false
end
