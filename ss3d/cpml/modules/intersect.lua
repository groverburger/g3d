--- Various geometric intersections
-- @module intersect

local modules     = (...):gsub('%.[^%.]+$', '') .. "."
local constants   = require(modules .. "constants")
local mat4        = require(modules .. "mat4")
local vec3        = require(modules .. "vec3")
local utils       = require(modules .. "utils")
local DBL_EPSILON = constants.DBL_EPSILON
local sqrt        = math.sqrt
local abs         = math.abs
local min         = math.min
local max         = math.max
local intersect   = {}

-- https://blogs.msdn.microsoft.com/rezanour/2011/08/07/barycentric-coordinates-and-point-in-triangle-tests/
-- point       is a vec3
-- triangle[1] is a vec3
-- triangle[2] is a vec3
-- triangle[3] is a vec3
function intersect.point_triangle(point, triangle)
	local u = triangle[2] - triangle[1]
	local v = triangle[3] - triangle[1]
	local w = point       - triangle[1]

	local vw = v:cross(w)
	local vu = v:cross(u)

	if vw:dot(vu) < 0 then
		return false
	end

	local uw = u:cross(w)
	local uv = u:cross(v)

	if uw:dot(uv) < 0 then
		return false
	end

	local d = uv:len()
	local r = vw:len() / d
	local t = uw:len() / d

	return r + t <= 1
end

-- point    is a vec3
-- aabb.min is a vec3
-- aabb.max is a vec3
function intersect.point_aabb(point, aabb)
	return
		aabb.min.x <= point.x and
		aabb.max.x >= point.x and
		aabb.min.y <= point.y and
		aabb.max.y >= point.y and
		aabb.min.z <= point.z and
		aabb.max.z >= point.z
end

-- point          is a vec3
-- frustum.left   is a plane { a, b, c, d }
-- frustum.right  is a plane { a, b, c, d }
-- frustum.bottom is a plane { a, b, c, d }
-- frustum.top    is a plane { a, b, c, d }
-- frustum.near   is a plane { a, b, c, d }
-- frustum.far    is a plane { a, b, c, d }
function intersect.point_frustum(point, frustum)
	local x, y, z = point:unpack()
	local planes  = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near,
		frustum.far or false
	}

	-- Skip the last test for infinite projections, it'll never fail.
	if not planes[6] then
		table.remove(planes)
	end

	local dot
	for i = 1, #planes do
		dot = planes[i].a * x + planes[i].b * y + planes[i].c * z + planes[i].d
		if dot <= 0 then
			return false
		end
	end

	return true
end

-- http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
-- ray.position  is a vec3
-- ray.direction is a vec3
-- triangle[1]   is a vec3
-- triangle[2]   is a vec3
-- triangle[3]   is a vec3
function intersect.ray_triangle(ray, triangle)
	local e1 = triangle[2] - triangle[1]
	local e2 = triangle[3] - triangle[1]
	local h  = ray.direction:cross(e2)
	local a  = h:dot(e1)

	-- if a is too close to 0, ray does not intersect triangle
	if abs(a) <= DBL_EPSILON then
		return false
	end

	local f = 1 / a
	local s = ray.position - triangle[1]
	local u = s:dot(h) * f

	-- ray does not intersect triangle
	if u < 0 or u > 1 then
		return false
	end

	local q = s:cross(e1)
	local v = ray.direction:dot(q) * f

	-- ray does not intersect triangle
	if v < 0 or u + v > 1 then
		return false
	end

	-- at this stage we can compute t to find out where
	-- the intersection point is on the line
	local t = q:dot(e2) * f

	-- return position of intersection and distance from ray origin
	if t >= DBL_EPSILON then
		return ray.position + ray.direction * t, t
	end

	-- ray does not intersect triangle
	return false
end

-- https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code
-- ray.position    is a vec3
-- ray.direction   is a vec3
-- sphere.position is a vec3
-- sphere.radius   is a number
function intersect.ray_sphere(ray, sphere)
	local offset = ray.position - sphere.position
	local b = offset:dot(ray.direction)
	local c = offset:dot(offset) - sphere.radius * sphere.radius

	-- ray's position outside sphere (c > 0)
	-- ray's direction pointing away from sphere (b > 0)
	if c > 0 and b > 0 then
		return false
	end

	local discr = b * b - c

	-- negative discriminant
	if discr < 0 then
		return false
	end

	-- Clamp t to 0
	local t = -b - sqrt(discr)
	t = t < 0 and 0 or t

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

-- http://gamedev.stackexchange.com/a/18459
-- ray.position  is a vec3
-- ray.direction is a vec3
-- aabb.min      is a vec3
-- aabb.max      is a vec3
function intersect.ray_aabb(ray, aabb)
	local dir     = ray.direction:normalize()
	local dirfrac = vec3(
		1 / dir.x,
		1 / dir.y,
		1 / dir.z
	)

	local t1 = (aabb.min.x - ray.position.x) * dirfrac.x
	local t2 = (aabb.max.x - ray.position.x) * dirfrac.x
	local t3 = (aabb.min.y - ray.position.y) * dirfrac.y
	local t4 = (aabb.max.y - ray.position.y) * dirfrac.y
	local t5 = (aabb.min.z - ray.position.z) * dirfrac.z
	local t6 = (aabb.max.z - ray.position.z) * dirfrac.z

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

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * tmin, tmin
end

-- http://stackoverflow.com/a/23976134/1190664
-- ray.position   is a vec3
-- ray.direction  is a vec3
-- plane.position is a vec3
-- plane.normal   is a vec3
function intersect.ray_plane(ray, plane)
	local denom = plane.normal:dot(ray.direction)

	-- ray does not intersect plane
	if abs(denom) < DBL_EPSILON then
		return false
	end

	-- distance of direction
	local d = plane.position - ray.position
	local t = d:dot(plane.normal) / denom

	if t < DBL_EPSILON then
		return false
	end

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

function intersect.ray_capsule(ray, capsule)
	local dist2, p1, p2 = intersect.closest_point_segment_segment(
		ray.position,
		ray.position + ray.direction * 1e10,
		capsule.a,
		capsule.b
	)
	if dist2 <= capsule.radius^2 then
		return p1
	end

	return false
end

-- https://web.archive.org/web/20120414063459/http://local.wasp.uwa.edu.au/~pbourke//geometry/lineline3d/
-- a[1] is a vec3
-- a[2] is a vec3
-- b[1] is a vec3
-- b[2] is a vec3
-- e    is a number
function intersect.line_line(a, b, e)
	-- new points
	local p13 = a[1] - b[1]
	local p43 = b[2] - b[1]
	local p21 = a[2] - a[1]

	-- if lengths are negative or too close to 0, lines do not intersect
	if p43:len2() < DBL_EPSILON or p21:len2() < DBL_EPSILON then
		return false
	end

	-- dot products
	local d1343 = p13:dot(p43)
	local d4321 = p43:dot(p21)
	local d1321 = p13:dot(p21)
	local d4343 = p43:dot(p43)
	local d2121 = p21:dot(p21)
	local denom = d2121 * d4343 - d4321 * d4321

	-- if denom is too close to 0, lines do not intersect
	if abs(denom) < DBL_EPSILON then
		return false
	end

	local numer = d1343 * d4321 - d1321 * d4343
	local mua   = numer / denom
	local mub   = (d1343 + d4321 * mua) / d4343

	-- return positions of intersection on each line
	local out1 = a[1] + p21 * mua
	local out2 = b[1] + p43 * mub
	local dist = out1:dist(out2)

	-- if distance of the shortest segment between lines is less than threshold
	if e and dist > e then
		return false
	end

	return { out1, out2 }, dist
end

-- a[1] is a vec3
-- a[2] is a vec3
-- b[1] is a vec3
-- b[2] is a vec3
-- e    is a number
function intersect.segment_segment(a, b, e)
	local c, d = intersect.line_line(a, b, e)

	if c and ((
		a[1].x <= c[1].x and
		a[1].y <= c[1].y and
		a[1].z <= c[1].z and
		c[1].x <= a[2].x and
		c[1].y <= a[2].y and
		c[1].z <= a[2].z
	) or (
		a[1].x >= c[1].x and
		a[1].y >= c[1].y and
		a[1].z >= c[1].z and
		c[1].x >= a[2].x and
		c[1].y >= a[2].y and
		c[1].z >= a[2].z
	)) and ((
		b[1].x <= c[2].x and
		b[1].y <= c[2].y and
		b[1].z <= c[2].z and
		c[2].x <= b[2].x and
		c[2].y <= b[2].y and
		c[2].z <= b[2].z
	) or (
		b[1].x >= c[2].x and
		b[1].y >= c[2].y and
		b[1].z >= c[2].z and
		c[2].x >= b[2].x and
		c[2].y >= b[2].y and
		c[2].z >= b[2].z
	)) then
		return c, d
	end

	-- segments do not intersect
	return false
end

-- a.min is a vec3
-- a.max is a vec3
-- b.min is a vec3
-- b.max is a vec3
function intersect.aabb_aabb(a, b)
	return
		a.min.x <= b.max.x and
		a.max.x >= b.min.x and
		a.min.y <= b.max.y and
		a.max.y >= b.min.y and
		a.min.z <= b.max.z and
		a.max.z >= b.min.z
end

-- aabb.position is a vec3
-- aabb.extent   is a vec3 (half-size)
-- obb.position  is a vec3
-- obb.extent    is a vec3 (half-size)
-- obb.rotation  is a mat4
function intersect.aabb_obb(aabb, obb)
	local a   = aabb.extent
	local b   = obb.extent
	local T   = obb.position - aabb.position
	local rot = mat4():transpose(obb.rotation)
	local B   = {}
	local t

	for i = 1, 3 do
		B[i] = {}
		for j = 1, 3 do
			assert((i - 1) * 4 + j < 16 and (i - 1) * 4 + j > 0)
			B[i][j] = abs(rot[(i - 1) * 4 + j]) + 1e-6
		end
	end

	t = abs(T.x)
	if not (t <= (b.x + a.x * B[1][1] + b.y * B[1][2] + b.z * B[1][3])) then return false end
	t = abs(T.x * B[1][1] + T.y * B[2][1] + T.z * B[3][1])
	if not (t <= (b.x + a.x * B[1][1] + a.y * B[2][1] + a.z * B[3][1])) then return false end
	t = abs(T.y)
	if not (t <= (a.y + b.x * B[2][1] + b.y * B[2][2] + b.z * B[2][3])) then return false end
	t = abs(T.z)
	if not (t <= (a.z + b.x * B[3][1] + b.y * B[3][2] + b.z * B[3][3])) then return false end
	t = abs(T.x * B[1][2] + T.y * B[2][2] + T.z * B[3][2])
	if not (t <= (b.y + a.x * B[1][2] + a.y * B[2][2] + a.z * B[3][2])) then return false end
	t = abs(T.x * B[1][3] + T.y * B[2][3] + T.z * B[3][3])
	if not (t <= (b.z + a.x * B[1][3] + a.y * B[2][3] + a.z * B[3][3])) then return false end
	t = abs(T.z * B[2][1] - T.y * B[3][1])
	if not (t <= (a.y * B[3][1] + a.z * B[2][1] + b.y * B[1][3] + b.z * B[1][2])) then return false end
	t = abs(T.z * B[2][2] - T.y * B[3][2])
	if not (t <= (a.y * B[3][2] + a.z * B[2][2] + b.x * B[1][3] + b.z * B[1][1])) then return false end
	t = abs(T.z * B[2][3] - T.y * B[3][3])
	if not (t <= (a.y * B[3][3] + a.z * B[2][3] + b.x * B[1][2] + b.y * B[1][1])) then return false end
	t = abs(T.x * B[3][1] - T.z * B[1][1])
	if not (t <= (a.x * B[3][1] + a.z * B[1][1] + b.y * B[2][3] + b.z * B[2][2])) then return false end
	t = abs(T.x * B[3][2] - T.z * B[1][2])
	if not (t <= (a.x * B[3][2] + a.z * B[1][2] + b.x * B[2][3] + b.z * B[2][1])) then return false end
	t = abs(T.x * B[3][3] - T.z * B[1][3])
	if not (t <= (a.x * B[3][3] + a.z * B[1][3] + b.x * B[2][2] + b.y * B[2][1])) then return false end
	t = abs(T.y * B[1][1] - T.x * B[2][1])
	if not (t <= (a.x * B[2][1] + a.y * B[1][1] + b.y * B[3][3] + b.z * B[3][2])) then return false end
	t = abs(T.y * B[1][2] - T.x * B[2][2])
	if not (t <= (a.x * B[2][2] + a.y * B[1][2] + b.x * B[3][3] + b.z * B[3][1])) then return false end
	t = abs(T.y * B[1][3] - T.x * B[2][3])
	if not (t <= (a.x * B[2][3] + a.y * B[1][3] + b.x * B[3][2] + b.y * B[3][1])) then return false end

	-- https://gamedev.stackexchange.com/questions/24078/which-side-was-hit
	-- Minkowski Sum
	local wy = (aabb.extent * 2 + obb.extent * 2) * (aabb.position.y - obb.position.y)
	local hx = (aabb.extent * 2 + obb.extent * 2) * (aabb.position.x - obb.position.x)

	if wy.x > hx.x and wy.y > hx.y and wy.z > hx.z then
		if wy.x > -hx.x and wy.y > -hx.y and wy.z > -hx.z then
			return vec3(obb.rotation * {  0, -1, 0, 1 })
		else
			return vec3(obb.rotation * { -1,  0, 0, 1 })
		end
	else
		if wy.x > -hx.x and wy.y > -hx.y and wy.z > -hx.z then
			return vec3(obb.rotation * { 1, 0, 0, 1 })
		else
			return vec3(obb.rotation * { 0, 1, 0, 1 })
		end
	end
end

-- http://stackoverflow.com/a/4579069/1190664
-- aabb.min        is a vec3
-- aabb.max        is a vec3
-- sphere.position is a vec3
-- sphere.radius   is a number
local axes = { "x", "y", "z" }
function intersect.aabb_sphere(aabb, sphere)
	local dist2 = sphere.radius ^ 2

	for _, axis in ipairs(axes) do
		local pos  = sphere.position[axis]
		local amin = aabb.min[axis]
		local amax = aabb.max[axis]

		if pos < amin then
			dist2 = dist2 - (pos - amin) ^ 2
		elseif pos > amax then
			dist2 = dist2 - (pos - amax) ^ 2
		end
	end

	return dist2 > 0
end

-- aabb.min       is a vec3
-- aabb.max       is a vec3
-- frustum.left   is a plane { a, b, c, d }
-- frustum.right  is a plane { a, b, c, d }
-- frustum.bottom is a plane { a, b, c, d }
-- frustum.top    is a plane { a, b, c, d }
-- frustum.near   is a plane { a, b, c, d }
-- frustum.far    is a plane { a, b, c, d }
function intersect.aabb_frustum(aabb, frustum)
	-- Indexed for the 'index trick' later
	local box = {
		aabb.min,
		aabb.max
	}

	-- We have 6 planes defining the frustum, 5 if infinite.
	local planes = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near,
		frustum.far or false
	}

	-- Skip the last test for infinite projections, it'll never fail.
	if not planes[6] then
		table.remove(planes)
	end

	for i = 1, #planes do
		-- This is the current plane
		local p = planes[i]

		-- p-vertex selection (with the index trick)
		-- According to the plane normal we can know the
		-- indices of the positive vertex
		local px = p.a > 0.0 and 2 or 1
		local py = p.b > 0.0 and 2 or 1
		local pz = p.c > 0.0 and 2 or 1

		-- project p-vertex on plane normal
		-- (How far is p-vertex from the origin)
		local dot = (p.a * box[px].x) + (p.b * box[py].y) + (p.c * box[pz].z)

		-- Doesn't intersect if it is behind the plane
		if dot < -p.d then
			return false
		end
	end

	return true
end

-- outer.min is a vec3
-- outer.max is a vec3
-- inner.min is a vec3
-- inner.max is a vec3
function intersect.encapsulate_aabb(outer, inner)
	return
		outer.min.x <= inner.min.x and
		outer.max.x >= inner.max.x and
		outer.min.y <= inner.min.y and
		outer.max.y >= inner.max.y and
		outer.min.z <= inner.min.z and
		outer.max.z >= inner.max.z
end

-- a.position is a vec3
-- a.radius   is a number
-- b.position is a vec3
-- b.radius   is a number
function intersect.circle_circle(a, b)
	return a.position:dist(b.position) <= a.radius + b.radius
end

-- a.position is a vec3
-- a.radius   is a number
-- b.position is a vec3
-- b.radius   is a number
function intersect.sphere_sphere(a, b)
	return intersect.circle_circle(a, b)
end

-- http://realtimecollisiondetection.net/blog/?p=103
-- sphere.position is a vec3
-- sphere.radius   is a number
-- triangle[1]     is a vec3
-- triangle[2]     is a vec3
-- triangle[3]     is a vec3
function intersect.sphere_triangle(sphere, triangle)
	-- Sphere is centered at origin
	local A  = triangle[1] - sphere.position
	local B  = triangle[2] - sphere.position
	local C  = triangle[3] - sphere.position

	-- Compute normal of triangle plane
	local V  = (B - A):cross(C - A)

	-- Test if sphere lies outside triangle plane
	local rr = sphere.radius * sphere.radius
	local d  = A:dot(V)
	local e  = V:dot(V)
	local s1 = d * d > rr * e

	-- Test if sphere lies outside triangle vertices
	local aa = A:dot(A)
	local ab = A:dot(B)
	local ac = A:dot(C)
	local bb = B:dot(B)
	local bc = B:dot(C)
	local cc = C:dot(C)

	local s2 = (aa > rr) and (ab > aa) and (ac > aa)
	local s3 = (bb > rr) and (ab > bb) and (bc > bb)
	local s4 = (cc > rr) and (ac > cc) and (bc > cc)

	-- Test is sphere lies outside triangle edges
	local AB = B - A
	local BC = C - B
	local CA = A - C

	local d1 = ab - aa
	local d2 = bc - bb
	local d3 = ac - cc

	local e1 = AB:dot(AB)
	local e2 = BC:dot(BC)
	local e3 = CA:dot(CA)

	local Q1 = A * e1 - d1 * AB
	local Q2 = B * e2 - d2 * BC
	local Q3 = C * e3 - d3 * CA

	local QC = C * e1 - Q1
	local QA = A * e2 - Q2
	local QB = B * e3 - Q3

	local s5 = (Q1:dot(Q1) > rr * e1 * e1) and (Q1:dot(QC) > 0)
	local s6 = (Q2:dot(Q2) > rr * e2 * e2) and (Q2:dot(QA) > 0)
	local s7 = (Q3:dot(Q3) > rr * e3 * e3) and (Q3:dot(QB) > 0)

	-- Return whether or not any of the tests passed
	return s1 or s2 or s3 or s4 or s5 or s6 or s7
end

-- sphere.position is a vec3
-- sphere.radius   is a number
-- frustum.left    is a plane { a, b, c, d }
-- frustum.right   is a plane { a, b, c, d }
-- frustum.bottom  is a plane { a, b, c, d }
-- frustum.top     is a plane { a, b, c, d }
-- frustum.near    is a plane { a, b, c, d }
-- frustum.far     is a plane { a, b, c, d }
function intersect.sphere_frustum(sphere, frustum)
	local x, y, z = sphere.position:unpack()
	local planes  = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near
	}

	if frustum.far then
		table.insert(planes, frustum.far, 5)
	end

	local dot
	for i = 1, #planes do
		dot = planes[i].a * x + planes[i].b * y + planes[i].c * z + planes[i].d

		if dot <= -sphere.radius then
			return false
		end
	end

	-- dot + radius is the distance of the object from the near plane.
	-- make sure that the near plane is the last test!
	return dot + sphere.radius
end

function intersect.capsule_capsule(c1, c2)
	local dist2, p1, p2 = intersect.closest_point_segment_segment(c1.a, c1.b, c2.a, c2.b)
	local radius = c1.radius + c2.radius

	if dist2 <= radius * radius then
		return p1, p2
	end

	return false
end

function intersect.closest_point_segment_segment(p1, p2, p3, p4)
	local s  -- Distance of intersection along segment 1
	local t  -- Distance of intersection along segment 2
	local c1 -- Collision point on segment 1
	local c2 -- Collision point on segment 2

	local d1 = p2 - p1 -- Direction of segment 1
	local d2 = p4 - p3 -- Direction of segment 2
	local r  = p1 - p3
	local a  = d1:dot(d1)
	local e  = d2:dot(d2)
	local f  = d2:dot(r)

	-- Check if both segments degenerate into points
	if a <= DBL_EPSILON and e <= DBL_EPSILON then
		s  = 0
		t  = 0
		c1 = p1
		c2 = p3
		return (c1 - c2):dot(c1 - c2), s, t, c1, c2
	end

	-- Check if segment 1 degenerates into a point
	if a <= DBL_EPSILON then
		s = 0
		t = utils.clamp(f / e, 0, 1)
	else
		local c = d1:dot(r)

		-- Check is segment 2 degenerates into a point
		if e <= DBL_EPSILON then
			t = 0
			s = utils.clamp(-c / a, 0, 1)
		else
			local b     = d1:dot(d2)
			local denom = a * e - b * b

			if abs(denom) > 0 then
				s = utils.clamp((b * f - c * e) / denom, 0, 1)
			else
				s = 0
			end

			t = (b * s + f) / e

			if t < 0 then
				t = 0
				s = utils.clamp(-c / a, 0, 1)
			elseif t > 1 then
				t = 1
				s = utils.clamp((b - c) / a, 0, 1)
			end
		end
	end

	c1 = p1 + d1 * s
	c2 = p3 + d2 * t

	return (c1 - c2):dot(c1 - c2), c1, c2, s, t
end

return intersect
