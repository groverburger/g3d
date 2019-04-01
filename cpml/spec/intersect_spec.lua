local intersect = require "modules.intersect"
local vec3      = require "modules.vec3"
local mat4      = require "modules.mat4"

describe("intersect:", function()
	it("intersects a point with a triangle", function()
		local a = vec3()
		local b = vec3(0, 0, 5)
		local c = {
			vec3(-1,  -1, 0),
			vec3( 1,  -1, 0),
			vec3( 0.5, 1, 0)
		}
		assert.is_true(intersect.point_triangle(a, c))
		assert.is_not_true(intersect.point_triangle(b, c))
	end)

	it("intersects a point with an aabb", function()
		local a = vec3()
		local b = vec3(0, 0, 5)
		local c = {
			min = vec3(-1),
			max = vec3( 1)
		}
		assert.is_true(intersect.point_aabb(a, c))
		assert.is_not_true(intersect.point_aabb(b, c))
	end)

	it("intersects a point with a frustum", function()
		pending("TODO")
	end)

	it("intersects a ray with a triangle", function()
		local a = {
			position  = vec3(0.5, 0.5, -1),
			direction = vec3(0,   0,    1)
		}
		local b = {
			position  = vec3(0.5, 0.5, -1),
			direction = vec3(0,   0,   -1)
		}
		local c = {
			vec3(-1,  -1, 0),
			vec3( 1,  -1, 0),
			vec3( 0.5, 1, 0)
		}
		assert.is_true(vec3.is_vec3(intersect.ray_triangle(a, c)))
		assert.is_not_true(intersect.ray_triangle(b, c))
	end)

	it("intersects a ray with a sphere", function()
		local a = {
			position  = vec3(0, 0, -2),
			direction = vec3(0, 0,  1)
		}
		local b = {
			position  = vec3(0, 0, -2),
			direction = vec3(0, 0, -1)
		}
		local c = {
			position = vec3(),
			radius   = 1
		}

		local w, x = intersect.ray_sphere(a, c)
		local y, z = intersect.ray_sphere(b, c)
		assert.is_true(vec3.is_vec3(w))
		assert.is_not_true(y)
	end)

	it("intersects a ray with an aabb", function()
		local a = {
			position  = vec3(0, 0, -2),
			direction = vec3(0, 0,  1)
		}
		local b = {
			position  = vec3(0, 0, -2),
			direction = vec3(0, 0, -1)
		}
		local c = {
			min = vec3(-1),
			max = vec3( 1)
		}

		local w, x = intersect.ray_aabb(a, c)
		local y, z = intersect.ray_aabb(b, c)
		assert.is_true(vec3.is_vec3(w))
		assert.is_not_true(y)
	end)

	it("intersects a ray with a plane", function()
		local a = {
			position  = vec3(0, 0,  1),
			direction = vec3(0, 0, -1)
		}
		local b = {
			position  = vec3(0, 0, 1),
			direction = vec3(0, 0, 1)
		}
		local c = {
			position = vec3(),
			normal   = vec3(0, 0, 1)
		}

		local w, x = intersect.ray_plane(a, c)
		local y, z = intersect.ray_plane(b, c)
		assert.is_true(vec3.is_vec3(w))
		assert.is_not_true(y)
	end)

	it("intersects a line with a line", function()
		local a = {
			vec3(0, 0, -1),
			vec3(0, 0,  1)
		}
		local b = {
			vec3(0, 0, -1),
			vec3(0, 1, -1)
		}
		local c = {
			vec3(-1, 0, 0),
			vec3( 1, 0, 0)
		}

		local w, x = intersect.line_line(a, c, 0.001)
		local y, z = intersect.line_line(b, c, 0.001)
		local u, v = intersect.line_line(b, c)
		assert.is_truthy(w)
		assert.is_not_truthy(y)
		assert.is_truthy(u)
	end)

	it("intersects a segment with a segment", function()
		local a = {
			vec3(0, 0, -1),
			vec3(0, 0,  1)
		}
		local b = {
			vec3(0, 0, -1),
			vec3(0, 1, -1)
		}
		local c = {
			vec3(-1, 0, 0),
			vec3( 1, 0, 0)
		}

		local w, x = intersect.segment_segment(a, c, 0.001)
		local y, z = intersect.segment_segment(b, c, 0.001)
		local u, v = intersect.segment_segment(b, c)
		assert.is_truthy(w)
		assert.is_not_truthy(y)
		assert.is_truthy(u)
	end)

	it("intersects an aabb with an aabb", function()
		local a = {
			min = vec3(-1),
			max = vec3( 1)
		}
		local b = {
			min = vec3(-5),
			max = vec3(-3)
		}
		local c = {
			min = vec3(),
			max = vec3(2)
		}
		assert.is_true(intersect.aabb_aabb(a, c))
		assert.is_not_true(intersect.aabb_aabb(b, c))
	end)

	it("intersects an aabb with an obb", function()
		local r = mat4():rotate(mat4(), math.pi / 4, vec3.unit_z)

		local a = {
			position = vec3(),
			extent   = vec3(0.5)
		}
		local b = {
			position = vec3(),
			extent   = vec3(0.5),
			rotation = r
		}
		local c = {
			position = vec3(0, 0, 2),
			extent   = vec3(0.5),
			rotation = r
		}
		assert.is_true(vec3.is_vec3(intersect.aabb_obb(a, b)))
		assert.is_not_true(intersect.aabb_obb(a, c))
	end)

	it("intersects an aabb with a sphere", function()
		local a = {
			min = vec3(-1),
			max = vec3( 1)
		}
		local b = {
			min = vec3(-5),
			max = vec3(-3)
		}
		local c = {
			position = vec3(0, 0, 3),
			radius   = 3
		}
		assert.is_true(intersect.aabb_sphere(a, c))
		assert.is_not_true(intersect.aabb_sphere(b, c))
	end)

	it("intersects an aabb with a frustum", function()
		pending("TODO")
	end)

	it("encapsulates an aabb", function()
		local a = {
			min = vec3(-1),
			max = vec3( 1)
		}
		local b = {
			min = vec3(-1.5),
			max = vec3( 1.5)
		}
		local c = {
			min = vec3(-0.5),
			max = vec3( 0.5)
		}
		local d = {
			min = vec3(-1),
			max = vec3( 1)
		}
		assert.is_true(intersect.encapsulate_aabb(a, d))
		assert.is_true(intersect.encapsulate_aabb(b, d))
		assert.is_not_true(intersect.encapsulate_aabb(c, d))
	end)

	it("intersects a circle with a circle", function()
		local a = {
			position = vec3(0, 0, 6),
			radius   = 3
		}
		local b = {
			position = vec3(0, 0, 7),
			radius   = 3
		}
		local c = {
			position = vec3(),
			radius   = 3
		}
		assert.is_true(intersect.circle_circle(a, c))
		assert.is_not_true(intersect.circle_circle(b, c))
	end)

	it("intersects a sphere with a sphere", function()
		local a = {
			position = vec3(0, 0, 6),
			radius   = 3
		}
		local b = {
			position = vec3(0, 0, 7),
			radius   = 3
		}
		local c = {
			position = vec3(),
			radius   = 3
		}
		assert.is_true(intersect.sphere_sphere(a, c))
		assert.is_not_true(intersect.sphere_sphere(b, c))
	end)

	it("intersects a sphere with a frustum", function()
		pending("TODO")
	end)

	it("intersects a capsule with another capsule", function()
		pending("TODO")
	end)
end)
