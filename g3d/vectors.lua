-- written by groverbuger for g3d
-- january 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- basic vector functions
----------------------------------------------------------------------------------------------------
-- vectors are just 3 numbers in table, defined like {1,0,0}

local vectors = {}

function vectors.normalizeVector(vector)
    local dist = math.sqrt(vector[1]^2 + vector[2]^2 + vector[3]^2)
    return {
        vector[1]/dist,
        vector[2]/dist,
        vector[3]/dist,
    }
end

function vectors.dotProduct(a,b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

function vectors.crossProduct(a,b)
    return {
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1],
    }
end

return vectors
