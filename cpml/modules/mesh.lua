--- Mesh utilities
-- @module mesh

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3    = require(modules .. "vec3")
local mesh    = {}

-- vertices is an arbitrary list of vec3s
function mesh.average(vertices)
	local out = vec3()
	for _, v in ipairs(vertices) do
		out = out + v
	end
	return out / #vertices
end

-- triangle[1] is a vec3
-- triangle[2] is a vec3
-- triangle[3] is a vec3
function mesh.normal(triangle)
	local ba = triangle[2] - triangle[1]
	local ca = triangle[3] - triangle[1]
	return ba:cross(ca):normalize()
end

-- triangle[1] is a vec3
-- triangle[2] is a vec3
-- triangle[3] is a vec3
function mesh.plane_from_triangle(triangle)
	return {
		origin = triangle[1],
		normal = mesh.normal(triangle)
	}
end

-- plane.origin is a vec3
-- plane.normal is a vec3
-- direction    is a vec3
function mesh.is_front_facing(plane, direction)
	return plane.normal:dot(direction) >= 0
end

-- point        is a vec3
-- plane.origin is a vec3
-- plane.normal is a vec3
-- plane.dot    is a number
function mesh.signed_distance(point, plane)
	return point:dot(plane.normal) - plane.normal:dot(plane.origin)
end

return mesh
