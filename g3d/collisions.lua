-- written by groverbuger for g3d
-- may 2021
-- MIT license

local vectors = require(g3d.path .. "/vectors")
local fastSubtract = vectors.subtract
local vectorAdd = vectors.add
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

----------------------------------------------------------------------------------------------------
-- collision detection functions
----------------------------------------------------------------------------------------------------
--
-- none of these functions are required for developing 3D games
-- however these collision functions are very frequently used in 3D games
--
-- be warned! a lot of this code is butt-ugly
-- using a table per vector would create a bazillion tables and lots of used memory
-- so instead all vectors are all represented using three number variables each
-- this approach ends up making the code look terrible, but collision functions need to be efficient

local collisions = {}

-- finds the closest point to the source point on the given line segment
local function closestPointOnLineSegment(
        a_x,a_y,a_z, -- point one of line segment
        b_x,b_y,b_z, -- point two of line segment
        x,y,z        -- source point
    )
    local ab_x, ab_y, ab_z = b_x - a_x, b_y - a_y, b_z - a_z
    local t = vectorDotProduct(x - a_x, y - a_y, z - a_z, ab_x, ab_y, ab_z) / (ab_x^2 + ab_y^2 + ab_z^2)
    t = math.min(1, math.max(0, t))
    return a_x + t*ab_x, a_y + t*ab_y, a_z + t*ab_z
end

-- model - ray intersection
-- based off of triangle - ray collision from excessive's CPML library
-- does a triangle - ray collision for every face in the model to find the shortest collision
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
local tiny = 2.2204460492503131e-16 -- the smallest possible value for a double, "double epsilon"
local function triangleRay(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        src_x, src_y, src_z,
        dir_x, dir_y, dir_z
    )

    -- cache these variables for efficiency
    local e11,e12,e13 = fastSubtract(tri_1_x,tri_1_y,tri_1_z, tri_0_x,tri_0_y,tri_0_z)
    local e21,e22,e23 = fastSubtract(tri_2_x,tri_2_y,tri_2_z, tri_0_x,tri_0_y,tri_0_z)
    local h1,h2,h3 = vectorCrossProduct(dir_x,dir_y,dir_z, e21,e22,e23)
    local a = vectorDotProduct(h1,h2,h3, e11,e12,e13)

    -- if a is too close to 0, ray does not intersect triangle
    if math.abs(a) <= tiny then
        return
    end

    local s1,s2,s3 = fastSubtract(src_x,src_y,src_z, tri_0_x,tri_0_y,tri_0_z)
    local u = vectorDotProduct(s1,s2,s3, h1,h2,h3) / a

    -- ray does not intersect triangle
    if u < 0 or u > 1 then
        return
    end

    local q1,q2,q3 = vectorCrossProduct(s1,s2,s3, e11,e12,e13)
    local v = vectorDotProduct(dir_x,dir_y,dir_z, q1,q2,q3) / a

    -- ray does not intersect triangle
    if v < 0 or u + v > 1 then
        return
    end

    -- at this stage we can compute t to find out where
    -- the intersection point is on the line
    local thisLength = vectorDotProduct(q1,q2,q3, e21,e22,e23) / a

    -- if hit this triangle and it's closer than any other hit triangle
    if thisLength >= tiny and (not finalLength or thisLength < finalLength) then
        --local norm_x, norm_y, norm_z = vectorCrossProduct(e11,e12,e13, e21,e22,e23)

        return thisLength, src_x + dir_x*thisLength, src_y + dir_y*thisLength, src_z + dir_z*thisLength, n_x,n_y,n_z
    end
end

-- detects a collision between a triangle and a sphere
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z, radius
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- collision not possible, just return
    if dist < -radius or dist > radius then
        return
    end

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local radiussq = radius * radius
    local smallestDist

    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    if dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line1_x, line1_y, line1_z
    end

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the closest point on the triangle from the source point given
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function trianglePoint(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    local smallestDist = dist
    itx_x, itx_y, itx_z = line1_x, line1_y, line1_z

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the collision point between a triangle and a capsule
-- capsules are defined with two points and a radius
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleCapsule(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        capn_x, capn_y, capn_z,
        radius
    )

    -- find the normal of this triangle
    -- tbd if necessary, this sometimes fixes weird edgecases
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    local dotOfNormals = math.abs(vectorDotProduct(n_x, n_y, n_z, capn_x, capn_y, capn_z))

    -- default reference point to an arbitrary point on the triangle
    -- for when dotOfNormals is 0, because then the capsule is parallel to the triangle
    local ref_x, ref_y, ref_z = tri_0_x, tri_0_y, tri_0_z

    if dotOfNormals > 0 then
        -- capsule is not parallel to the triangle's plane
        -- find where the capsule's normal vector intersects the triangle's plane
        local t = vectorDotProduct(n_x, n_y, n_z, (tri_0_x - base_x) / dotOfNormals, (tri_0_y - base_y) / dotOfNormals, (tri_0_z - base_z) / dotOfNormals)
        local plane_itx_x, plane_itx_y, plane_itx_z = base_x + capn_x*t, base_y + capn_y*t, base_z + capn_z*t
        local _

        -- then clamp that plane intersect point onto the triangle itself
        -- this is the new reference point
        _, ref_x, ref_y, ref_z = trianglePoint(
            tri_0_x, tri_0_y, tri_0_z,
            tri_1_x, tri_1_y, tri_1_z,
            tri_2_x, tri_2_y, tri_2_z,
            n_x, n_y, n_z,
            plane_itx_x, plane_itx_y, plane_itx_z
        )
    end

    -- find the closest point on the capsule line to the reference point
    local c_x, c_y, c_z = closestPointOnLineSegment(a_x, a_y, a_z, b_x, b_y, b_z, ref_x, ref_y, ref_z)

    -- do a sphere cast from that closest point to the triangle and return the result
    return triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        c_x, c_y, c_z, radius
    )
end

-- finds whether or not a triangle is inside an AABB
-- NOTE: this only works with AABBs that are cubes! may not give the correct result for non-cube AABBs
-- TODO: replace this with seperating axis theorem
local function triangleAABB(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        min_x, min_y, min_z,
        max_x, max_y, max_z
    )

    -- get the closest point from the centerpoint on the triangle
    local len,x,y,z,nx,ny,nz = trianglePoint(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        (min_x+max_x)*0.5, (min_y+max_y)*0.5, (min_z+max_z)*0.5
    )

    -- if the point is not inside the AABB, return nothing
    if not (x >= min_x and x <= max_x) then return end
    if not (y >= min_y and y <= max_y) then return end
    if not (z >= min_z and z <= max_z) then return end

    -- the point is inside the AABB, return the collision data
    return len, x,y,z, nx,ny,nz
end

-- runs a given intersection function on all of the triangles made up of a given vert table
local function findClosest(self, verts, func, ...)
    -- declare the variables that will be returned by the function
    local finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z

    -- cache references to this model's properties for efficiency
    local translation_x = self.translation[1]
    local translation_y = self.translation[2]
    local translation_z = self.translation[3]
    local scale_x = self.scale[1]
    local scale_y = self.scale[2]
    local scale_z = self.scale[3]

    for v=1, #verts, 3 do
        -- apply the function given with the arguments given
        -- also supply the points of the current triangle
        local n_x, n_y, n_z = vectorNormalize(
            verts[v][6]*scale_x,
            verts[v][7]*scale_x,
            verts[v][8]*scale_x
        )

        local length, wx,wy,wz, nx,ny,nz = func(
            verts[v][1]*scale_x + translation_x,
            verts[v][2]*scale_y + translation_y,
            verts[v][3]*scale_z + translation_z,
            verts[v+1][1]*scale_x + translation_x,
            verts[v+1][2]*scale_y + translation_y,
            verts[v+1][3]*scale_z + translation_z,
            verts[v+2][1]*scale_x + translation_x,
            verts[v+2][2]*scale_y + translation_y,
            verts[v+2][3]*scale_z + translation_z,
            n_x,
            n_y,
            n_z,
            ...
        )

        -- if something was hit
        -- and either the finalLength is not yet defined or the new length is closer
        -- then update the collision information
        if length and (not finalLength or length < finalLength) then
            finalLength = length
            where_x = wx
            where_y = wy
            where_z = wz
            norm_x = nx
            norm_y = ny
            norm_z = nz
        end
    end

    -- normalize the normal vector before it is returned
    if finalLength then
        norm_x, norm_y, norm_z = vectorNormalize(norm_x, norm_y, norm_z)
    end

    -- return all the information in a standardized way
    return finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z
end

function collisions:rayIntersection(src_x, src_y, src_z, dir_x, dir_y, dir_z)
    return findClosest(self, self.verts, triangleRay, src_x, src_y, src_z, dir_x, dir_y, dir_z)
end

function collisions:sphereIntersection(src_x, src_y, src_z, radius)
    return findClosest(self, self.verts, triangleSphere, src_x, src_y, src_z, radius)
end

function collisions:closestPoint(src_x, src_y, src_z)
    return findClosest(self, self.verts, trianglePoint, src_x, src_y, src_z)
end

function collisions:capsuleIntersection(tip_x, tip_y, tip_z, base_x, base_y, base_z, radius)
    -- the normal vector coming out the tip of the capsule
    local norm_x, norm_y, norm_z = vectorNormalize(tip_x - base_x, tip_y - base_y, tip_z - base_z)

    -- the base and tip, inset by the radius
    -- these two coordinates are the actual extent of the capsule sphere line
    local a_x, a_y, a_z = base_x + norm_x*radius, base_y + norm_y*radius, base_z + norm_z*radius
    local b_x, b_y, b_z = tip_x - norm_x*radius, tip_y - norm_y*radius, tip_z - norm_z*radius

    return findClosest(
        self,
        self.verts,
        triangleCapsule,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        norm_x, norm_y, norm_z,
        radius
    )
end

----------------------------------------------------------------------------------------------------
-- AABB functions
----------------------------------------------------------------------------------------------------
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
--
-- sources:
--     https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
function collisions:isIntersectionAABB(other)
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
    local min = self.aabb.min
    local max = self.aabb.max

    local in_x = x >= min[1]*self.scale[1] + self.translation[1] and x <= max[1]*self.scale[1] + self.translation[1]
    local in_y = y >= min[2]*self.scale[2] + self.translation[2] and y <= max[2]*self.scale[2] + self.translation[2]
    local in_z = z >= min[3]*self.scale[3] + self.translation[3] and z <= max[3]*self.scale[3] + self.translation[3]

    return in_x and in_y and in_z
end

-- returns the distance from the point given to the origin of the model
function collisions:getDistanceFrom(x,y,z)
    return math.sqrt((x - self.translation[1])^2 + (y - self.translation[2])^2 + (z - self.translation[3])^2)
end

-- AABB - ray intersection
-- based off of ray - AABB intersection from excessive's CPML library
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://gamedev.stackexchange.com/a/18459
function collisions:rayIntersectionAABB(src_1, src_2, src_3, dir_1, dir_2, dir_3)
    local dir_1, dir_2, dir_3 = vectorNormalize(dir_1, dir_2, dir_3)

    local t1 = (self.aabb.min[1]*self.scale[1] + self.translation[1] - src_1) / dir_1
    local t2 = (self.aabb.max[1]*self.scale[1] + self.translation[1] - src_1) / dir_1
    local t3 = (self.aabb.min[2]*self.scale[2] + self.translation[2] - src_2) / dir_2
    local t4 = (self.aabb.max[2]*self.scale[2] + self.translation[2] - src_2) / dir_2
    local t5 = (self.aabb.min[3]*self.scale[3] + self.translation[3] - src_3) / dir_3
    local t6 = (self.aabb.max[3]*self.scale[3] + self.translation[3] - src_3) / dir_3

    local min = math.min
    local max = math.max
    local tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
    local tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))

    -- ray is intersecting AABB, but whole AABB is behind us
    if tmax < 0 then
        return false
    end

    -- ray does not intersect AABB
    if tmin > tmax then
        return false
    end

    -- return distance and the collision coordinates
    local where_1 = src_1 + dir_1 * tmin
    local where_2 = src_2 + dir_2 * tmin
    local where_3 = src_3 + dir_3 * tmin
    return tmin, where_1, where_2, where_3
end

return collisions
