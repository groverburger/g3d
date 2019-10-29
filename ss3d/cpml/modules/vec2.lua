--- A 2 component vector.
-- @module vec2

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3    = require(modules .. "vec3")
local acos    = math.acos
local atan2   = math.atan2
local sqrt    = math.sqrt
local cos     = math.cos
local sin     = math.sin
local vec2    = {}
local vec2_mt = {}

-- Private constructor.
local function new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0
	}, vec2_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y;} cpml_vec2;"
		new = ffi.typeof("cpml_vec2")
	end
end

--- Constants
-- @table vec2
-- @field unit_x X axis of rotation
-- @field unit_y Y axis of rotation
-- @field zero Empty vector
vec2.unit_x = new(1, 0)
vec2.unit_y = new(0, 1)
vec2.zero   = new(0, 0)

--- The public constructor.
-- @param x Can be of three types: </br>
-- number X component
-- table {x, y} or {x = x, y = y}
-- scalar to fill the vector eg. {x, x}
-- @tparam number y Y component
-- @treturn vec2 out
function vec2.new(x, y)
	-- number, number
	if x and y then
		assert(type(x) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(y) == "number", "new: Wrong argument type for y (<number> expected)")

		return new(x, y)

	-- {x, y} or {x=x, y=y}
	elseif type(x) == "table" then
		local xx, yy = x.x or x[1], x.y or x[2]
		assert(type(xx) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(yy) == "number", "new: Wrong argument type for y (<number> expected)")

		return new(xx, yy)

	-- number
	elseif type(x) == "number" then
		return new(x, x)
	else
		return new()
	end
end

--- Convert point from polar to cartesian.
-- @tparam number radius Radius of the point
-- @tparam number theta Angle of the point (in radians)
-- @treturn vec2 out
function vec2.from_cartesian(radius, theta)
	return new(radius * cos(theta), radius * sin(theta))
end

--- Clone a vector.
-- @tparam vec2 a Vector to be cloned
-- @treturn vec2 out
function vec2.clone(a)
	return new(a.x, a.y)
end

--- Add two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.add(a, b)
	return new(
		a.x + b.x,
		a.y + b.y
	)
end

--- Subtract one vector from another.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.sub(a, b)
	return new(
		a.x - b.x,
		a.y - b.y
	)
end

--- Multiply a vector by another vector.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.mul(a, b)
	return new(
		a.x * b.x,
		a.y * b.y
	)
end

--- Divide a vector by another vector.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.div(a, b)
	return new(
		a.x / b.x,
		a.y / b.y
	)
end

--- Get the normal of a vector.
-- @tparam vec2 a Vector to normalize
-- @treturn vec2 out
function vec2.normalize(a)
	if a:is_zero() then
		return new()
	end
	return a:scale(1 / a:len())
end

--- Trim a vector to a given length.
-- @tparam vec2 a Vector to be trimmed
-- @tparam number len Length to trim the vector to
-- @treturn vec2 out
function vec2.trim(a, len)
	return a:normalize():scale(math.min(a:len(), len))
end

--- Get the cross product of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number magnitude
function vec2.cross(a, b)
	return a.x * b.y - a.y * b.x
end

--- Get the dot product of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dot
function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

--- Get the length of a vector.
-- @tparam vec2 a Vector to get the length of
-- @treturn number len
function vec2.len(a)
	return sqrt(a.x * a.x + a.y * a.y)
end

--- Get the squared length of a vector.
-- @tparam vec2 a Vector to get the squared length of
-- @treturn number len
function vec2.len2(a)
	return a.x * a.x + a.y * a.y
end

--- Get the distance between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dist
function vec2.dist(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return sqrt(dx * dx + dy * dy)
end

--- Get the squared distance between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dist
function vec2.dist2(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return dx * dx + dy * dy
end

--- Scale a vector by a scalar.
-- @tparam vec2 a Left hand operand
-- @tparam number b Right hand operand
-- @treturn vec2 out
function vec2.scale(a, b)
	return new(
		a.x * b,
		a.y * b
	)
end

--- Rotate a vector.
-- @tparam vec2 a Vector to rotate
-- @tparam number phi Angle to rotate vector by (in radians)
-- @treturn vec2 out
function vec2.rotate(a, phi)
	local c = cos(phi)
	local s = sin(phi)
	return new(
		c * a.x - s * a.y,
		s * a.x + c * a.y
	)
end

--- Get the perpendicular vector of a vector.
-- @tparam vec2 a Vector to get perpendicular axes from
-- @treturn vec2 out
function vec2.perpendicular(a)
	return new(-a.y, a.x)
end

--- Angle from one vector to another.
-- @tparam vec2 a Vector
-- @tparam vec2 b Vector
-- @treturn number angle
function vec2.angle_to(a, b)
	if b then
		return atan2(a.y - b.y, a.x - b.x)
	end

	return atan2(a.y, a.x)
end

--- Angle between two vectors.
-- @tparam vec2 a Vector
-- @tparam vec2 b Vector
-- @treturn number angle
function vec2.angle_between(a, b)
	if b then
		if vec2.is_vec2(a) then
			return acos(a:dot(b) / (a:len() * b:len()))
		end

		return acos(vec3.dot(a, b) / (vec3.len(a) * vec3.len(b)))
	end

	return 0
end

--- Lerp between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @tparam number s Step value
-- @treturn vec2 out
function vec2.lerp(a, b, s)
	return a + (b - a) * s
end

--- Unpack a vector into individual components.
-- @tparam vec2 a Vector to unpack
-- @treturn number x
-- @treturn number y
function vec2.unpack(a)
	return a.x, a.y
end

--- Return the component-wise minimum of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 A vector where each component is the lesser value for that component between the two given vectors.
function vec2.component_min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y))
end

--- Return the component-wise maximum of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 A vector where each component is the lesser value for that component between the two given vectors.
function vec2.component_max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y))
end


--- Return a boolean showing if a table is or is not a vec2.
-- @tparam vec2 a Vector to be tested
-- @treturn boolean is_vec2
function vec2.is_vec2(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_vec2", a)
	end

	return
		type(a)   == "table"  and
		type(a.x) == "number" and
		type(a.y) == "number"
end

--- Return a boolean showing if a table is or is not a zero vec2.
-- @tparam vec2 a Vector to be tested
-- @treturn boolean is_zero
function vec2.is_zero(a)
	return a.x == 0 and a.y == 0
end

--- Convert point from cartesian to polar.
-- @tparam vec2 a Vector to convert
-- @treturn number radius
-- @treturn number theta
function vec2.to_polar(a)
	local radius = sqrt(a.x^2 + a.y^2)
	local theta  = atan2(a.y, a.x)
	theta = theta > 0 and theta or theta + 2 * math.pi
	return radius, theta
end

--- Return a formatted string.
-- @tparam vec2 a Vector to be turned into a string
-- @treturn string formatted
function vec2.to_string(a)
	return string.format("(%+0.3f,%+0.3f)", a.x, a.y)
end

vec2_mt.__index    = vec2
vec2_mt.__tostring = vec2.to_string

function vec2_mt.__call(_, x, y)
	return vec2.new(x, y)
end

function vec2_mt.__unm(a)
	return new(-a.x, -a.y)
end

function vec2_mt.__eq(a, b)
	if not vec2.is_vec2(a) or not vec2.is_vec2(b) then
		return false
	end
	return a.x == b.x and a.y == b.y
end

function vec2_mt.__add(a, b)
	assert(vec2.is_vec2(a), "__add: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b), "__add: Wrong argument type for right hand operand. (<cpml.vec2> expected)")
	return a:add(b)
end

function vec2_mt.__sub(a, b)
	assert(vec2.is_vec2(a), "__add: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b), "__add: Wrong argument type for right hand operand. (<cpml.vec2> expected)")
	return a:sub(b)
end

function vec2_mt.__mul(a, b)
	assert(vec2.is_vec2(a), "__mul: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b) or type(b) == "number", "__mul: Wrong argument type for right hand operand. (<cpml.vec2> or <number> expected)")

	if vec2.is_vec2(b) then
		return a:mul(b)
	end

	return a:scale(b)
end

function vec2_mt.__div(a, b)
	assert(vec2.is_vec2(a), "__div: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b) or type(b) == "number", "__div: Wrong argument type for right hand operand. (<cpml.vec2> or <number> expected)")

	if vec2.is_vec2(b) then
		return a:div(b)
	end

	return a:scale(1 / b)
end

if status then
	ffi.metatype(new, vec2_mt)
end

return setmetatable({}, vec2_mt)
