--- A quaternion and associated utilities.
-- @module quat

local modules       = (...):gsub('%.[^%.]+$', '') .. "."
local constants     = require(modules .. "constants")
local vec3          = require(modules .. "vec3")
local DOT_THRESHOLD = constants.DOT_THRESHOLD
local DBL_EPSILON   = constants.DBL_EPSILON
local acos          = math.acos
local cos           = math.cos
local sin           = math.sin
local min           = math.min
local max           = math.max
local sqrt          = math.sqrt
local quat          = {}
local quat_mt       = {}

-- Private constructor.
local function new(x, y, z, w)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		z = z or 0,
		w = w or 1
	}, quat_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y, z, w;} cpml_quat;"
		new = ffi.typeof("cpml_quat")
	end
end

-- Statically allocate a temporary variable used in some of our functions.
local tmp = new()
local qv, uv, uuv = vec3(), vec3(), vec3()

--- Constants
-- @table quat
-- @field unit Unit quaternion
-- @field zero Empty quaternion
quat.unit = new(0, 0, 0, 1)
quat.zero = new(0, 0, 0, 0)

--- The public constructor.
-- @param x Can be of two types: </br>
-- number x X component
-- table {x, y, z, w} or {x=x, y=y, z=z, w=w}
-- @tparam number y Y component
-- @tparam number z Z component
-- @tparam number w W component
-- @treturn quat out
function quat.new(x, y, z, w)
	-- number, number, number, number
	if x and y and z and w then
		assert(type(x) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(y) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(z) == "number", "new: Wrong argument type for z (<number> expected)")
		assert(type(w) == "number", "new: Wrong argument type for w (<number> expected)")

		return new(x, y, z, w)

	-- {x, y, z, w} or {x=x, y=y, z=z, w=w}
	elseif type(x) == "table" then
		local xx, yy, zz, ww = x.x or x[1], x.y or x[2], x.z or x[3], x.w or x[4]
		assert(type(xx) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(yy) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(zz) == "number", "new: Wrong argument type for z (<number> expected)")
		assert(type(ww) == "number", "new: Wrong argument type for w (<number> expected)")

		return new(xx, yy, zz, ww)
	end

	return new(0, 0, 0, 1)
end

--- Create a quaternion from an angle/axis pair.
-- @tparam number angle Angle (in radians)
-- @param axis/x -- Can be of two types, a vec3 axis, or the x component of that axis
-- @param y axis -- y component of axis (optional, only if x component param used)
-- @param z axis -- z component of axis (optional, only if x component param used)
-- @treturn quat out
function quat.from_angle_axis(angle, axis, a3, a4)
	if axis and a3 and a4 then
		local x, y, z = axis, a3, a4
		local s = sin(angle * 0.5)
		local c = cos(angle * 0.5)
		return new(x * s, y * s, z * s, c)
	else
		return quat.from_angle_axis(angle, axis.x, axis.y, axis.z)
	end
end

--- Create a quaternion from a normal/up vector pair.
-- @tparam vec3 normal
-- @tparam vec3 up (optional)
-- @treturn quat out
function quat.from_direction(normal, up)
	local u = up or vec3.unit_z
	local n = normal:normalize()
	local a = u:cross(n)
	local d = u:dot(n)
	return new(a.x, a.y, a.z, d + 1)
end

--- Clone a quaternion.
-- @tparam quat a Quaternion to clone
-- @treturn quat out
function quat.clone(a)
	return new(a.x, a.y, a.z, a.w)
end

--- Add two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat out
function quat.add(a, b)
	return new(
		a.x + b.x,
		a.y + b.y,
		a.z + b.z,
		a.w + b.w
	)
end

--- Subtract a quaternion from another.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat out
function quat.sub(a, b)
	return new(
		a.x - b.x,
		a.y - b.y,
		a.z - b.z,
		a.w - b.w
	)
end

--- Multiply two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat quaternion equivalent to "apply b, then a"
function quat.mul(a, b)
	return new(
		a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
		a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
		a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
	)
end

--- Multiply a quaternion and a vec3.
-- @tparam quat a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn quat out
function quat.mul_vec3(a, b)
	qv.x = a.x
	qv.y = a.y
	qv.z = a.z
	uv   = qv:cross(b)
	uuv  = qv:cross(uv)
	return b + ((uv * a.w) + uuv) * 2
end

--- Raise a normalized quaternion to a scalar power.
-- @tparam quat a Left hand operand (should be a unit quaternion)
-- @tparam number s Right hand operand
-- @treturn quat out
function quat.pow(a, s)
	-- Do it as a slerp between identity and a (code borrowed from slerp)
	if a.w < 0 then
		a   = -a
	end
	local dot = a.w

	if dot > DOT_THRESHOLD then
		return a:scale(s)
	end

	dot = min(max(dot, -1), 1)

	local theta = acos(dot) * s
	local c = new(a.x, a.y, a.z, 0):normalize() * sin(theta)
	c.w = cos(theta)
	return c
end

--- Normalize a quaternion.
-- @tparam quat a Quaternion to normalize
-- @treturn quat out
function quat.normalize(a)
	if a:is_zero() then
		return new(0, 0, 0, 0)
	end
	return a:scale(1 / a:len())
end

--- Get the dot product of two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn number dot
function quat.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

--- Return the length of a quaternion.
-- @tparam quat a Quaternion to get length of
-- @treturn number len
function quat.len(a)
	return sqrt(a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w)
end

--- Return the squared length of a quaternion.
-- @tparam quat a Quaternion to get length of
-- @treturn number len
function quat.len2(a)
	return a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
end

--- Multiply a quaternion by a scalar.
-- @tparam quat a Left hand operand
-- @tparam number s Right hand operand
-- @treturn quat out
function quat.scale(a, s)
	return new(
		a.x * s,
		a.y * s,
		a.z * s,
		a.w * s
	)
end

--- Alias of from_angle_axis.
-- @tparam number angle Angle (in radians)
-- @param axis/x -- Can be of two types, a vec3 axis, or the x component of that axis
-- @param y axis -- y component of axis (optional, only if x component param used)
-- @param z axis -- z component of axis (optional, only if x component param used)
-- @treturn quat out
function quat.rotate(angle, axis, a3, a4)
	return quat.from_angle_axis(angle, axis, a3, a4)
end

--- Return the conjugate of a quaternion.
-- @tparam quat a Quaternion to conjugate
-- @treturn quat out
function quat.conjugate(a)
	return new(-a.x, -a.y, -a.z, a.w)
end

--- Return the inverse of a quaternion.
-- @tparam quat a Quaternion to invert
-- @treturn quat out
function quat.inverse(a)
	tmp.x = -a.x
	tmp.y = -a.y
	tmp.z = -a.z
	tmp.w =  a.w
	return tmp:normalize()
end

--- Return the reciprocal of a quaternion.
-- @tparam quat a Quaternion to reciprocate
-- @treturn quat out
function quat.reciprocal(a)
	if a:is_zero() then
		error("Cannot reciprocate a zero quaternion")
		return false
	end

	tmp.x = -a.x
	tmp.y = -a.y
	tmp.z = -a.z
	tmp.w =  a.w

	return tmp:scale(1 / a:len2())
end

--- Lerp between two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @tparam number s Step value
-- @treturn quat out
function quat.lerp(a, b, s)
	return (a + (b - a) * s):normalize()
end

--- Slerp between two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @tparam number s Step value
-- @treturn quat out
function quat.slerp(a, b, s)
	local dot = a:dot(b)

	if dot < 0 then
		a   = -a
		dot = -dot
	end

	if dot > DOT_THRESHOLD then
		return a:lerp(b, s)
	end

	dot = min(max(dot, -1), 1)

	local theta = acos(dot) * s
	local c = (b - a * dot):normalize()
	return a * cos(theta) + c * sin(theta)
end

--- Unpack a quaternion into individual components.
-- @tparam quat a Quaternion to unpack
-- @treturn number x
-- @treturn number y
-- @treturn number z
-- @treturn number w
function quat.unpack(a)
	return a.x, a.y, a.z, a.w
end

--- Return a boolean showing if a table is or is not a quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_quat
function quat.is_quat(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_quat", a)
	end

	return
		type(a)   == "table"  and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number" and
		type(a.w) == "number"
end

--- Return a boolean showing if a table is or is not a zero quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_zero
function quat.is_zero(a)
	return
		a.x == 0 and
		a.y == 0 and
		a.z == 0 and
		a.w == 0
end

--- Return a boolean showing if a table is or is not a real quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_real
function quat.is_real(a)
	return
		a.x == 0 and
		a.y == 0 and
		a.z == 0
end

--- Return a boolean showing if a table is or is not an imaginary quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_imaginary
function quat.is_imaginary(a)
	return a.w == 0
end

--- Convert a quaternion into an angle plus axis components.
-- @tparam quat a Quaternion to convert
-- @treturn number angle
-- @treturn x axis-x
-- @treturn y axis-y
-- @treturn z axis-z
function quat.to_angle_axis_unpack(a)
	if a.w > 1 or a.w < -1 then
		a = a:normalize()
	end

	local x, y, z
	local angle = 2 * acos(a.w)
	local s     = sqrt(1 - a.w * a.w)

	if s < DBL_EPSILON then
		x = a.x
		y = a.y
		z = a.z
	else
		x = a.x / s
		y = a.y / s
		z = a.z / s
	end

	return angle, x, y, z
end

--- Convert a quaternion into an angle/axis pair.
-- @tparam quat a Quaternion to convert
-- @treturn number angle
-- @treturn vec3 axis
function quat.to_angle_axis(a)
	local angle, x, y, z = a:to_angle_axis_unpack()
	return angle, vec3(x, y, z)
end

--- Convert a quaternion into a vec3.
-- @tparam quat a Quaternion to convert
-- @treturn vec3 out
function quat.to_vec3(a)
	return vec3(a.x, a.y, a.z)
end

--- Return a formatted string.
-- @tparam quat a Quaternion to be turned into a string
-- @treturn string formatted
function quat.to_string(a)
	return string.format("(%+0.3f,%+0.3f,%+0.3f,%+0.3f)", a.x, a.y, a.z, a.w)
end

quat_mt.__index    = quat
quat_mt.__tostring = quat.to_string

function quat_mt.__call(_, x, y, z, w)
	return quat.new(x, y, z, w)
end

function quat_mt.__unm(a)
	return a:scale(-1)
end

function quat_mt.__eq(a,b)
	if not quat.is_quat(a) or not quat.is_quat(b) then
		return false
	end
	return a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w
end

function quat_mt.__add(a, b)
	assert(quat.is_quat(a), "__add: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b), "__add: Wrong argument type for right hand operand. (<cpml.quat> expected)")
	return a:add(b)
end

function quat_mt.__sub(a, b)
	assert(quat.is_quat(a), "__sub: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b), "__sub: Wrong argument type for right hand operand. (<cpml.quat> expected)")
	return a:sub(b)
end

function quat_mt.__mul(a, b)
	assert(quat.is_quat(a), "__mul: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b) or vec3.is_vec3(b) or type(b) == "number", "__mul: Wrong argument type for right hand operand. (<cpml.quat> or <cpml.vec3> or <number> expected)")

	if quat.is_quat(b) then
		return a:mul(b)
	end

	if type(b) == "number" then
		return a:scale(b)
	end

	return a:mul_vec3(b)
end

function quat_mt.__pow(a, n)
	assert(quat.is_quat(a), "__pow: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(type(n) == "number", "__pow: Wrong argument type for right hand operand. (<number> expected)")
	return a:pow(n)
end

if status then
	ffi.metatype(new, quat_mt)
end

return setmetatable({}, quat_mt)
