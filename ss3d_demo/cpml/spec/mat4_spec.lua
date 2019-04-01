local mat4  = require "modules.mat4"
local vec3  = require "modules.vec3"
local utils = require "modules.utils"

describe("mat4:", function()
	it("creates an identity matrix", function()
		local a = mat4()
		assert.is.equal(1, a[1])
		assert.is.equal(0, a[2])
		assert.is.equal(0, a[3])
		assert.is.equal(0, a[4])
		assert.is.equal(0, a[5])
		assert.is.equal(1, a[6])
		assert.is.equal(0, a[7])
		assert.is.equal(0, a[8])
		assert.is.equal(0, a[9])
		assert.is.equal(0, a[10])
		assert.is.equal(1, a[11])
		assert.is.equal(0, a[12])
		assert.is.equal(0, a[13])
		assert.is.equal(0, a[14])
		assert.is.equal(0, a[15])
		assert.is.equal(1, a[16])
		assert.is_true(a:is_mat4())
	end)

	it("creates a filled matrix", function()
		local a = mat4 {
			3, 3, 3, 3,
			4, 4, 4, 4,
			5, 5, 5, 5,
			6, 6, 6, 6
		}
		assert.is.equal(3, a[1])
		assert.is.equal(3, a[2])
		assert.is.equal(3, a[3])
		assert.is.equal(3, a[4])
		assert.is.equal(4, a[5])
		assert.is.equal(4, a[6])
		assert.is.equal(4, a[7])
		assert.is.equal(4, a[8])
		assert.is.equal(5, a[9])
		assert.is.equal(5, a[10])
		assert.is.equal(5, a[11])
		assert.is.equal(5, a[12])
		assert.is.equal(6, a[13])
		assert.is.equal(6, a[14])
		assert.is.equal(6, a[15])
		assert.is.equal(6, a[16])
	end)

	it("creates a filled matrix from vec4s", function()
		local a = mat4 {
			{ 3, 3, 3, 3 },
			{ 4, 4, 4, 4 },
			{ 5, 5, 5, 5 },
			{ 6, 6, 6, 6 }
		}
		assert.is.equal(3, a[1])
		assert.is.equal(3, a[2])
		assert.is.equal(3, a[3])
		assert.is.equal(3, a[4])
		assert.is.equal(4, a[5])
		assert.is.equal(4, a[6])
		assert.is.equal(4, a[7])
		assert.is.equal(4, a[8])
		assert.is.equal(5, a[9])
		assert.is.equal(5, a[10])
		assert.is.equal(5, a[11])
		assert.is.equal(5, a[12])
		assert.is.equal(6, a[13])
		assert.is.equal(6, a[14])
		assert.is.equal(6, a[15])
		assert.is.equal(6, a[16])
	end)

	it("creates a filled matrix from a 3x3 matrix", function()
		local a = mat4 {
			3, 3, 3,
			4, 4, 4,
			5, 5, 5
		}
		assert.is.equal(3, a[1])
		assert.is.equal(3, a[2])
		assert.is.equal(3, a[3])
		assert.is.equal(0, a[4])
		assert.is.equal(4, a[5])
		assert.is.equal(4, a[6])
		assert.is.equal(4, a[7])
		assert.is.equal(0, a[8])
		assert.is.equal(5, a[9])
		assert.is.equal(5, a[10])
		assert.is.equal(5, a[11])
		assert.is.equal(0, a[12])
		assert.is.equal(0, a[13])
		assert.is.equal(0, a[14])
		assert.is.equal(0, a[15])
		assert.is.equal(1, a[16])
	end)

	it("creates a matrix from perspective", function()
		local a = mat4.from_perspective(45, 1, 0.1, 1000)
		assert.is_true(utils.tolerance( 2.414-a[1],  0.001))
		assert.is_true(utils.tolerance( 2.414-a[6],  0.001))
		assert.is_true(utils.tolerance(-1    -a[11], 0.001))
		assert.is_true(utils.tolerance(-1    -a[12], 0.001))
		assert.is_true(utils.tolerance(-0.2  -a[15], 0.001))
	end)

	it("creates a matrix from HMD perspective", function()
		local t = {
			LeftTan  = 2.3465312,
			RightTan = 0.9616399,
			UpTan    = 2.8664987,
			DownTan  = 2.8664987
		}
		local a = mat4.from_hmd_perspective(t, 0.1, 1000, false, false)
		assert.is_true(utils.tolerance(a[1] -  0.605, 0.001))
		assert.is_true(utils.tolerance(a[6] -  0.349, 0.001))
		assert.is_true(utils.tolerance(a[9] - -0.419, 0.001))
		assert.is_true(utils.tolerance(a[11]- -1.000, 0.001))
		assert.is_true(utils.tolerance(a[12]- -1.000, 0.001))
		assert.is_true(utils.tolerance(a[15]- -0.200, 0.001))
	end)

	it("clones a matrix", function()
		local a = mat4.identity()
		local b = a:clone()
		assert.is.equal(a, b)
	end)

	it("multiplies two 4x4 matrices", function()
		local a = mat4 {
			1,  2,  3,  4,
			5,  6,  7,  8,
			9,  10, 11, 12,
			13, 14, 15, 16
		}
		local b = mat4 {
			1, 5, 9,  13,
			2, 6, 10, 14,
			3, 7, 11, 15,
			4, 8, 12, 16
		}
		local c = mat4():mul(a, b)
		local d = a * b
		assert.is.equal(30,  c[1])
		assert.is.equal(70,  c[2])
		assert.is.equal(110, c[3])
		assert.is.equal(150, c[4])
		assert.is.equal(70,  c[5])
		assert.is.equal(174, c[6])
		assert.is.equal(278, c[7])
		assert.is.equal(382, c[8])
		assert.is.equal(110, c[9])
		assert.is.equal(278, c[10])
		assert.is.equal(446, c[11])
		assert.is.equal(614, c[12])
		assert.is.equal(150, c[13])
		assert.is.equal(382, c[14])
		assert.is.equal(614, c[15])
		assert.is.equal(846, c[16])
		assert.is.equal(c, d)
	end)

	it("multiplies a matrix and a vec4", function()
		local a = mat4 {
			1,  2,  3,  4,
			5,  6,  7,  8,
			9,  10, 11, 12,
			13, 14, 15, 16
		}
		local b = { 10, 20, 30, 40 }
		local c = mat4.mul_vec4(mat4(), a, b)
		local d = a * b
		assert.is.equal(900,  c[1])
		assert.is.equal(1000, c[2])
		assert.is.equal(1100, c[3])
		assert.is.equal(1200, c[4])

		assert.is.equal(c[1], d[1])
		assert.is.equal(c[2], d[2])
		assert.is.equal(c[3], d[3])
		assert.is.equal(c[4], d[4])
	end)

	it("scales a matrix", function()
		local a = mat4():scale(mat4(), vec3(5, 5, 5))
		assert.is.equal(5, a[1])
		assert.is.equal(5, a[6])
		assert.is.equal(5, a[11])
	end)

	it("rotates a matrix", function()
		local a = mat4():rotate(mat4(), math.rad(45), vec3.unit_z)
		assert.is_true(utils.tolerance( 0.7071-a[1], 0.001))
		assert.is_true(utils.tolerance( 0.7071-a[2], 0.001))
		assert.is_true(utils.tolerance(-0.7071-a[5], 0.001))
		assert.is_true(utils.tolerance( 0.7071-a[6], 0.001))
	end)

	it("translates a matrix", function()
		local a = mat4():translate(mat4(), vec3(5, 5, 5))
		assert.is.equal(5, a[13])
		assert.is.equal(5, a[14])
		assert.is.equal(5, a[15])
	end)

	it("inverts a matrix", function()
		local a = mat4()
		a = a:rotate(a, math.pi/4, vec3.unit_y)
		a = a:translate(a, vec3(4, 5, 6))

		local b = mat4.invert(mat4(), a)
		local c = a * b
		assert.is.equal(mat4(), c)

		local d = mat4()
		d:rotate(d, math.pi/4, vec3.unit_y)
		d:translate(d, vec3(4, 5, 6))

		local e = -d
		local f = d * e
		assert.is.equal(mat4(), f)
	end)

	it("transposes a matrix", function()
		local a = mat4({
			1, 1, 1, 1,
			2, 2, 2, 2,
			3, 3, 3, 3,
			4, 4, 4, 4
		})
		a = a:transpose(a)
		assert.is.equal(1, a[1])
		assert.is.equal(2, a[2])
		assert.is.equal(3, a[3])
		assert.is.equal(4, a[4])
		assert.is.equal(1, a[5])
		assert.is.equal(2, a[6])
		assert.is.equal(3, a[7])
		assert.is.equal(4, a[8])
		assert.is.equal(1, a[9])
		assert.is.equal(2, a[10])
		assert.is.equal(3, a[11])
		assert.is.equal(4, a[12])
		assert.is.equal(1, a[13])
		assert.is.equal(2, a[14])
		assert.is.equal(3, a[15])
		assert.is.equal(4, a[16])
	end)

	it("shears a matrix", function()
		local yx, zx, xy, zy, xz, yz = 1, 1, 1, -1, -1, -1
		local a = mat4():shear(mat4(), yx, zx, xy, zy, xz, yz)
		assert.is.equal( 1, a[2])
		assert.is.equal( 1, a[3])
		assert.is.equal( 1, a[5])
		assert.is.equal(-1, a[7])
		assert.is.equal(-1, a[9])
		assert.is.equal(-1, a[10])
	end)

	it("reflects a matrix along a plane", function()
		local origin = vec3(5, 1, 0)
		local normal = vec3(0, -1, 0):normalize()
		local a = mat4():reflect(mat4(), origin, normal)
		local p = a * vec3(-5, 2, 5)
		assert.is.equal(p.x, -5)
		assert.is.equal(p.y, 0)
		assert.is.equal(p.z, 5)
	end)

	it("projects a matrix into screen space", function()
		local v  = vec3(0, 0, 10)
		local a  = mat4()
		local b  = mat4.from_perspective(45, 1, 0.1, 1000)
		local vp = { 0, 0, 400, 400 }
		local c  = mat4.project(v, a, b, vp)
		assert.is.equal(200, c.x)
		assert.is.equal(200, c.y)
		assert.is_true(utils.tolerance(1.0101-c.z, 0.001))
	end)

	it("unprojects a matrix into world space", function()
		local v  = vec3(0, 0, 10)
		local a  = mat4()
		local b  = mat4.from_perspective(45, 1, 0.1, 1000)
		local vp = { 0, 0, 400, 400 }
		local c  = mat4.project(v, a, b, vp)
		local d  = mat4.unproject(c, a, b, vp)
		assert.is_true(utils.tolerance(v.x-d.x, 0.001))
		assert.is_true(utils.tolerance(v.y-d.y, 0.001))
		assert.is_true(utils.tolerance(v.z-d.z, 0.001))
	end)

	it("transforms a matrix to look at a point", function()
		local e = vec3(0, 0, 1.55)
		local c = vec3(4, 7, 1)
		local u = vec3(0, 0, 1)
		local a = mat4():look_at(mat4(), e, c, u)

		assert.is_true(utils.tolerance( 0.868-a[1], 0.001))
		assert.is_true(utils.tolerance( 0.034-a[2], 0.001))
		assert.is_true(utils.tolerance(-0.495-a[3], 0.001))
		assert.is_true(utils.tolerance( 0    -a[4], 0.001))

		assert.is_true(utils.tolerance(-0.496-a[5], 0.001))
		assert.is_true(utils.tolerance( 0.059-a[6], 0.001))
		assert.is_true(utils.tolerance(-0.866-a[7], 0.001))
		assert.is_true(utils.tolerance( 0    -a[8], 0.001))

		assert.is_true(utils.tolerance( 0    -a[9],  0.001))
		assert.is_true(utils.tolerance( 0.998-a[10], 0.001))
		assert.is_true(utils.tolerance( 0.068-a[11], 0.001))
		assert.is_true(utils.tolerance( 0    -a[12], 0.001))

		assert.is_true(utils.tolerance( 0    -a[13], 0.001))
		assert.is_true(utils.tolerance(-1.546-a[14], 0.001))
		assert.is_true(utils.tolerance(-0.106-a[15], 0.001))
		assert.is_true(utils.tolerance( 1    -a[16], 0.001))
	end)

	it("converts a matrix to vec4s", function()
		local a = mat4()
		local v = a:to_vec4s()
		assert.is_true(type(v)    == "table")
		assert.is_true(type(v[1]) == "table")
		assert.is_true(type(v[2]) == "table")
		assert.is_true(type(v[3]) == "table")
		assert.is_true(type(v[4]) == "table")

		assert.is.equal(1, v[1][1])
		assert.is.equal(0, v[1][2])
		assert.is.equal(0, v[1][3])
		assert.is.equal(0, v[1][4])

		assert.is.equal(0, v[2][1])
		assert.is.equal(1, v[2][2])
		assert.is.equal(0, v[2][3])
		assert.is.equal(0, v[2][4])

		assert.is.equal(0, v[3][1])
		assert.is.equal(0, v[3][2])
		assert.is.equal(1, v[3][3])
		assert.is.equal(0, v[3][4])

		assert.is.equal(0, v[4][1])
		assert.is.equal(0, v[4][2])
		assert.is.equal(0, v[4][3])
		assert.is.equal(1, v[4][4])
	end)

	it("converts a matrix to a quaternion", function()
		local q = mat4({
			0, 0, 1, 0,
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 0, 0
		}):to_quat()
		assert.is.equal(-0.5, q.x)
		assert.is.equal(-0.5, q.y)
		assert.is.equal(-0.5, q.z)
		assert.is.equal( 0.5, q.w)
	end)

	it("converts a matrix to a frustum", function()
		local a = mat4()
		local b = mat4.from_perspective(45, 1, 0.1, 1000)
		local f = (b * a):to_frustum()

		assert.is_true(utils.tolerance( 0.9239-f.left.a, 0.001))
		assert.is_true(utils.tolerance( 0     -f.left.b, 0.001))
		assert.is_true(utils.tolerance(-0.3827-f.left.c, 0.001))
		assert.is_true(utils.tolerance( 0     -f.left.d, 0.001))

		assert.is_true(utils.tolerance(-0.9239-f.right.a, 0.001))
		assert.is_true(utils.tolerance( 0     -f.right.b, 0.001))
		assert.is_true(utils.tolerance(-0.3827-f.right.c, 0.001))
		assert.is_true(utils.tolerance( 0     -f.right.d, 0.001))

		assert.is_true(utils.tolerance( 0     -f.bottom.a, 0.001))
		assert.is_true(utils.tolerance( 0.9239-f.bottom.b, 0.001))
		assert.is_true(utils.tolerance(-0.3827-f.bottom.c, 0.001))
		assert.is_true(utils.tolerance( 0     -f.bottom.d, 0.001))

		assert.is_true(utils.tolerance( 0     -f.top.a, 0.001))
		assert.is_true(utils.tolerance(-0.9239-f.top.b, 0.001))
		assert.is_true(utils.tolerance(-0.3827-f.top.c, 0.001))
		assert.is_true(utils.tolerance( 0     -f.top.d, 0.001))

		assert.is_true(utils.tolerance( 0  -f.near.a, 0.001))
		assert.is_true(utils.tolerance( 0  -f.near.b, 0.001))
		assert.is_true(utils.tolerance(-1  -f.near.c, 0.001))
		assert.is_true(utils.tolerance(-0.1-f.near.d, 0.001))

		assert.is_true(utils.tolerance( 0   -f.far.a, 0.001))
		assert.is_true(utils.tolerance( 0   -f.far.b, 0.001))
		assert.is_true(utils.tolerance( 1   -f.far.c, 0.001))
		assert.is_true(utils.tolerance( 1000-f.far.d, 0.001))
	end)

	it("checks to see if data is a valid matrix (not a table)", function()
		assert.is_not_true(mat4.is_mat4(0))
	end)

	it("checks to see if data is a valid matrix (invalid data)", function()
		assert.is_not_true(mat4.is_mat4({}))
	end)

	it("gets a string representation of a matrix", function()
		local a = mat4():to_string()
		local z = "+0.000"
		local o = "+1.000"
		local s = string.format(
			"[ %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s ]",
			o, z, z, z, z, o, z, z, z, z, o, z, z, z ,z, o
		)
		assert.is.equal(s, a)
	end)
end)

--[[
	from_angle_axis
	from_quaternion
	from_direction
	from_transform
	from_ortho
--]]
