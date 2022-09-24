-- written by groverbuger for g3d
-- september 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- vector functions
----------------------------------------------------------------------------------------------------
-- some basic vector functions that don't use tables
-- because these functions will happen often, this is done to avoid frequent memory allocation

local vectors = {}

function vectors.subtract(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end

function vectors.add(v1,v2,v3, v4,v5,v6)
    return v1+v4, v2+v5, v3+v6
end

function vectors.scalarMultiply(scalar, v1,v2,v3)
    return v1*scalar, v2*scalar, v3*scalar
end

function vectors.crossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

function vectors.dotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

function vectors.normalize(x,y,z)
    local mag = math.sqrt(x^2 + y^2 + z^2)
    if mag ~= 0 then
        return x/mag, y/mag, z/mag
    else
        return 0, 0, 0
    end
end

function vectors.magnitude(x,y,z)
    return math.sqrt(x^2 + y^2 + z^2)
end

return vectors
