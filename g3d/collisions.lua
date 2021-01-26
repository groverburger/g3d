-- written by groverbuger for g3d
-- january 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- collision detection functions
----------------------------------------------------------------------------------------------------

local collisions = {}

-- generate an axis-aligned bounding box
-- very useful for less precise collisions, like hitboxes
--
-- translation, and scale are not included here because they are computed on the fly instead
-- rotation is never included because AABBs are axis-aligned
function collisions:generateAABB()
    local aabb = {
        min = {
            math.huge,
            math.huge,
            math.huge,
        },
        max = {
            -1*math.huge,
            -1*math.huge,
            -1*math.huge
        }
    }

    for _,vert in ipairs(self.verts) do
        aabb.min[1] = math.min(aabb.min[1], vert[1])
        aabb.min[2] = math.min(aabb.min[2], vert[2])
        aabb.min[3] = math.min(aabb.min[3], vert[3])
        aabb.max[1] = math.max(aabb.max[1], vert[1])
        aabb.max[2] = math.max(aabb.max[2], vert[2])
        aabb.max[3] = math.max(aabb.max[3], vert[3])
    end

    self.aabb = aabb
    return aabb
end

-- check if two models have intersecting AABBs
-- other argument is another model
function collisions:isIntersectionAABB(other)
    -- make sure AABBs exist if they don't already
    if not self.aabb then self:generateAABB() end
    if not other.aabb then other:generateAABB() end

    -- cache these references
    local a_min = self.aabb.min
    local a_max = self.aabb.max
    local b_min = other.aabb.min
    local b_max = other.aabb.max

    -- make shorter variable names for translation
    local a_1 = self.translation[1]
    local a_2 = self.translation[2]
    local a_3 = self.translation[3]
    local b_1 = other.translation[1]
    local b_2 = other.translation[2]
    local b_3 = other.translation[3]

    -- do the calculation
    local x = a_min[1]*self.scale[1] + a_1 <= b_max[1]*other.scale[1] + b_1 and a_max[1]*self.scale[1] + a_1 >= b_min[1]*other.scale[1] + b_1
    local y = a_min[2]*self.scale[2] + a_2 <= b_max[2]*other.scale[2] + b_2 and a_max[2]*self.scale[2] + a_2 >= b_min[2]*other.scale[2] + b_2
    local z = a_min[3]*self.scale[3] + a_3 <= b_max[3]*other.scale[3] + b_3 and a_max[3]*self.scale[3] + a_3 >= b_min[3]*other.scale[3] + b_3
    return x and y and z
end

-- check if a given point is inside the model's AABB
function collisions:isPointInsideAABB(x,y,z)
    if not self.aabb then self:generateAABB() end

    local min = self.aabb.min
    local max = self.aabb.max

    local in_x = x >= min[1]*self.scale[1] + self.translation[1] and x <= max[1]*self.scale[1] + self.translation[1]
    local in_y = y >= min[2]*self.scale[2] + self.translation[2] and y <= max[2]*self.scale[2] + self.translation[2]
    local in_z = z >= min[3]*self.scale[3] + self.translation[3] and z <= max[3]*self.scale[3] + self.translation[3]

    return in_x and in_y and in_z
end

-- returns the distance from the point given to the origin of the model
function collisions:pointDistance(x,y,z)
    return math.sqrt((x - self.translation[1])^2 + (y - self.translation[2])^2 + (z - self.translation[3])^2)
end

-- define some basic vector functions that don't use tables
-- for efficiency purposes, as collision functions must be fast
local function fastSubtractVector(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end
local function fastCrossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end
local function fastDotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

-- model - ray collision
-- based off of triangle - ray collision from excessive's CPML library
-- does a triangle - ray collision for every face in the model to find the shortest collision
--
-- returns the distane from source point to collision point,
-- the x,y,z coordinates of the collision point,
-- and the x,y,z of the surface normal of the triangle that was hit
--
-- NOTE: ignores rotation!
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
local abs = math.abs
local tiny = 2.2204460492503131e-16 -- the smallest possible value for a double, "double epsilon"
function collisions:isRayCollision(src_1, src_2, src_3, dir_1, dir_2, dir_3)
    -- declare the variables that will be returned by the function
    local finalLength, where_x, where_y, where_z
    local norm_x, norm_y, norm_z

    -- cache references to this model's properties for efficiency
    local translation_x = self.translation[1]
    local translation_y = self.translation[2]
    local translation_z = self.translation[3]
    local scale_x = self.scale[1]
    local scale_y = self.scale[2]
    local scale_z = self.scale[3]
    local verts = self.verts

    for v=1, #verts, 3 do
        -- do a dot product to check if this face is a backface
        -- if this is a backface, don't check it for collision
        if fastDotProduct(verts[v][6],verts[v][7],verts[v][8], dir_1,dir_2,dir_3) < 0 then
            -- cache these variables for efficiency
            local tri_1_1 = verts[v][1]*scale_x + translation_x
            local tri_1_2 = verts[v][2]*scale_y + translation_y
            local tri_1_3 = verts[v][3]*scale_z + translation_z
            local tri_2_1 = verts[v+1][1]*scale_x + translation_x
            local tri_2_2 = verts[v+1][2]*scale_y + translation_y
            local tri_2_3 = verts[v+1][3]*scale_z + translation_z
            local tri_3_1 = verts[v+2][1]*scale_x + translation_x
            local tri_3_2 = verts[v+2][2]*scale_y + translation_y
            local tri_3_3 = verts[v+2][3]*scale_z + translation_z
            local e11,e12,e13 = fastSubtractVector(tri_2_1,tri_2_2,tri_2_3, tri_1_1,tri_1_2,tri_1_3)
            local e21,e22,e23 = fastSubtractVector(tri_3_1,tri_3_2,tri_3_3, tri_1_1,tri_1_2,tri_1_3)
            local h1,h2,h3 = fastCrossProduct(dir_1,dir_2,dir_3, e21,e22,e23)
            local a = fastDotProduct(h1,h2,h3, e11,e12,e13)

            -- if a is too close to 0, ray does not intersect triangle
            if abs(a) <= tiny then
                goto after_intersection_test
            end

            local s1,s2,s3 = fastSubtractVector(src_1,src_2,src_3, tri_1_1,tri_1_2,tri_1_3)
            local u = fastDotProduct(s1,s2,s3, h1,h2,h3) / a

            -- ray does not intersect triangle
            if u < 0 or u > 1 then
                goto after_intersection_test
            end

            local q1,q2,q3 = fastCrossProduct(s1,s2,s3, e11,e12,e13)
            local v = fastDotProduct(dir_1,dir_2,dir_3, q1,q2,q3) / a

            -- ray does not intersect triangle
            if v < 0 or u + v > 1 then
                goto after_intersection_test
            end

            -- at this stage we can compute t to find out where
            -- the intersection point is on the line
            local thisLength = fastDotProduct(q1,q2,q3, e21,e22,e23) / a

            -- if hit this triangle and it's closer than any other hit triangle
            if thisLength >= tiny and (not finalLength or thisLength < finalLength) then
                finalLength = thisLength
                where_x = src_1 + dir_1*thisLength
                where_y = src_2 + dir_2*thisLength
                where_z = src_3 + dir_3*thisLength
                
                -- store the surface normal of the triangle the ray collided with
                norm_x, norm_y, norm_z = fastCrossProduct(e11,e12,e13, e21,e22,e23)
            end

            ::after_intersection_test::
        end
    end

    return finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z
end

return collisions
