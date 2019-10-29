--- double 4x4, 1-based, column major matrices
-- @module mat4
local modules   = (...):gsub('%.[^%.]+$', '') .. "."
local constants = require(modules .. "constants")
local vec2      = require(modules .. "vec2")
local vec3      = require(modules .. "vec3")
local quat      = require(modules .. "quat")
local utils     = require(modules .. "utils")
local sqrt      = math.sqrt
local cos       = math.cos
local sin       = math.sin
local tan       = math.tan
local rad       = math.rad
local mat4      = {}
local mat4_mt   = {}

-- Private constructor.
local function new(m)
	m = m or {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	}
	m._m = m
	return setmetatable(m, mat4_mt)
end
 -- Convert matrix into identity
local function identity(m)
	m[1],  m[2],  m[3],  m[4]  = 1, 0, 0, 0
	m[5],  m[6],  m[7],  m[8]  = 0, 1, 0, 0
	m[9],  m[10], m[11], m[12] = 0, 0, 1, 0
	m[13], m[14], m[15], m[16] = 0, 0, 0, 1
	return m
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi, the_type
if type(jit) == "table" and jit.status() then
   --  status, ffi = pcall(require, "ffi")
    if status then
        ffi.cdef "typedef struct { double _m[16]; } cpml_mat4;"
        new = ffi.typeof("cpml_mat4")
    end
end

-- Statically allocate a temporary variable used in some of our functions.
local tmp = new()
local tm4 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
local tv4 = { 0, 0, 0, 0 }
local forward, side, new_up = vec3(), vec3(), vec3()

--- The public constructor.
-- @param a Can be of four types: </br>
-- table Length 16 (4x4 matrix)
-- table Length 9 (3x3 matrix)
-- table Length 4 (4 vec4s)
-- nil
-- @treturn mat4 out
function mat4.new(a)
	local out = new()

	-- 4x4 matrix
	if type(a) == "table" and #a == 16 then
		for i = 1, 16 do
			out[i] = tonumber(a[i])
		end

	-- 3x3 matrix
	elseif type(a) == "table" and #a == 9 then
		out[1], out[2],  out[3]  = a[1], a[2], a[3]
		out[5], out[6],  out[7]  = a[4], a[5], a[6]
		out[9], out[10], out[11] = a[7], a[8], a[9]
		out[16] = 1

	-- 4 vec4s
	elseif type(a) == "table" and type(a[1]) == "table" then
		local idx = 1
		for i = 1, 4 do
			for j = 1, 4 do
				out[idx] = a[i][j]
				idx = idx + 1
			end
		end

	-- nil
	else
		out[1]  = 1
		out[6]  = 1
		out[11] = 1
		out[16] = 1
	end

	return out
end

--- Create an identity matrix.
-- @tparam mat4 a Matrix to overwrite
-- @treturn mat4 out
function mat4.identity(a)
	return identity(a or new())
end

--- Create a matrix from an angle/axis pair.
-- @tparam number angle Angle of rotation
-- @tparam vec3 axis Axis of rotation
-- @treturn mat4 out
function mat4.from_angle_axis(angle, axis)
	local l = axis:len()
	if l == 0 then
		return new()
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	return new {
		x*x*(1-c)+c,   y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
		x*y*(1-c)-z*s, y*y*(1-c)+c,   y*z*(1-c)+x*s, 0,
		x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c,   0,
		0, 0, 0, 1
	}
end

--- Create a matrix from a quaternion.
-- @tparam quat q Rotation quaternion
-- @treturn mat4 out
function mat4.from_quaternion(q)
	return mat4.from_angle_axis(q:to_angle_axis())
end

--- Create a matrix from a direction/up pair.
-- @tparam vec3 direction Vector direction
-- @tparam vec3 up Up direction
-- @treturn mat4 out
function mat4.from_direction(direction, up)
	local forward = vec3.normalize(direction)
	local side = vec3.cross(forward, up):normalize()
	local new_up = vec3.cross(side, forward):normalize()

	local out = new()
	out[1]    = side.x
	out[5]    = side.y
	out[9]    = side.z
	out[2]    = new_up.x
	out[6]    = new_up.y
	out[10]   = new_up.z
	out[3]    = forward.x
	out[7]    = forward.y
	out[11]   = forward.z
	out[16]   = 1

	return out
end

--- Create a matrix from a transform.
-- @tparam vec3 trans Translation vector
-- @tparam quat rot Rotation quaternion
-- @tparam vec3 scale Scale vector
-- @treturn mat4 out
function mat4.from_transform(trans, rot, scale)
	local angle, axis = rot:to_angle_axis()
	local l = axis:len()

	if l == 0 then
		return new()
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	return new {
		x*x*(1-c)+c,   y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
		x*y*(1-c)-z*s, y*y*(1-c)+c,   y*z*(1-c)+x*s, 0,
		x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c,   0,
		trans.x, trans.y, trans.z, 1
	}
end

--- Create matrix from orthogonal.
-- @tparam number left
-- @tparam number right
-- @tparam number top
-- @tparam number bottom
-- @tparam number near
-- @tparam number far
-- @treturn mat4 out
function mat4.from_ortho(left, right, top, bottom, near, far)
	local out = new()
	out[1]    =  2 / (right - left)
	out[6]    =  2 / (top - bottom)
	out[11]   = -2 / (far - near)
	out[13]   = -((right + left) / (right - left))
	out[14]   = -((top + bottom) / (top - bottom))
	out[15]   = -((far + near) / (far - near))
	out[16]   =  1

	return out
end

--- Create matrix from perspective.
-- @tparam number fovy Field of view
-- @tparam number aspect Aspect ratio
-- @tparam number near Near plane
-- @tparam number far Far plane
-- @treturn mat4 out
function mat4.from_perspective(fovy, aspect, near, far)
	assert(aspect ~= 0)
	assert(near   ~= far)

	local t   = tan(rad(fovy) / 2)
	local out = new()
	out[1]    =  1 / (t * aspect)
	out[6]    =  1 / t
	out[11]   = -(far + near) / (far - near)
	out[12]   = -1
	out[15]   = -(2 * far * near) / (far - near)
	out[16]   =  0

	return out
end

-- Adapted from the Oculus SDK.
--- Create matrix from HMD perspective.
-- @tparam number tanHalfFov Tangent of half of the field of view
-- @tparam number zNear Near plane
-- @tparam number zFar Far plane
-- @tparam boolean flipZ Z axis is flipped or not
-- @tparam boolean farAtInfinity Far plane is infinite or not
-- @treturn mat4 out
function mat4.from_hmd_perspective(tanHalfFov, zNear, zFar, flipZ, farAtInfinity)
	-- CPML is right-handed and intended for GL, so these don't need to be arguments.
	local rightHanded = true
	local isOpenGL    = true

	local function CreateNDCScaleAndOffsetFromFov(tanHalfFov)
		x_scale  = 2 / (tanHalfFov.LeftTan + tanHalfFov.RightTan)
		x_offset =     (tanHalfFov.LeftTan - tanHalfFov.RightTan) * x_scale * 0.5
		y_scale  = 2 / (tanHalfFov.UpTan   + tanHalfFov.DownTan )
		y_offset =     (tanHalfFov.UpTan   - tanHalfFov.DownTan ) * y_scale * 0.5

		local result = {
			Scale  = vec2(x_scale, y_scale),
			Offset = vec2(x_offset, y_offset)
		}

		-- Hey - why is that Y.Offset negated?
		-- It's because a projection matrix transforms from world coords with Y=up,
		-- whereas this is from NDC which is Y=down.
		 return result
	end

	if not flipZ and farAtInfinity then
		print("Error: Cannot push Far Clip to Infinity when Z-order is not flipped")
		farAtInfinity = false
	end

	 -- A projection matrix is very like a scaling from NDC, so we can start with that.
	local scaleAndOffset  = CreateNDCScaleAndOffsetFromFov(tanHalfFov)
	local handednessScale = rightHanded and -1.0 or 1.0
	local projection      = new()

	-- Produces X result, mapping clip edges to [-w,+w]
	projection[1] = scaleAndOffset.Scale.x
	projection[2] = 0
	projection[3] = handednessScale * scaleAndOffset.Offset.x
	projection[4] = 0

	-- Produces Y result, mapping clip edges to [-w,+w]
	-- Hey - why is that YOffset negated?
	-- It's because a projection matrix transforms from world coords with Y=up,
	-- whereas this is derived from an NDC scaling, which is Y=down.
	projection[5] = 0
	projection[6] = scaleAndOffset.Scale.y
	projection[7] = handednessScale * -scaleAndOffset.Offset.y
	projection[8] = 0

	-- Produces Z-buffer result - app needs to fill this in with whatever Z range it wants.
	-- We'll just use some defaults for now.
	projection[9]  = 0
	projection[10] = 0

	if farAtInfinity then
		if isOpenGL then
			-- It's not clear this makes sense for OpenGL - you don't get the same precision benefits you do in D3D.
			projection[11] = -handednessScale
			projection[12] = 2.0 * zNear
		else
			projection[11] = 0
			projection[12] = zNear
		end
	else
		if isOpenGL then
			-- Clip range is [-w,+w], so 0 is at the middle of the range.
			projection[11] = -handednessScale * (flipZ and -1.0 or 1.0) * (zNear + zFar) / (zNear - zFar)
			projection[12] = 2.0 * ((flipZ and -zFar or zFar) * zNear) / (zNear - zFar)
		else
			-- Clip range is [0,+w], so 0 is at the start of the range.
			projection[11] = -handednessScale * (flipZ and -zNear or zFar) / (zNear - zFar)
			projection[12] = ((flipZ and -zFar or zFar) * zNear) / (zNear - zFar)
		end
	end

	-- Produces W result (= Z in)
	projection[13] = 0
	projection[14] = 0
	projection[15] = handednessScale
	projection[16] = 0

	return projection:transpose(projection)
end

--- Clone a matrix.
-- @tparam mat4 a Matrix to clone
-- @treturn mat4 out
function mat4.clone(a)
	return new(a)
end

--- Multiply two matrices.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Left hand operand
-- @tparam mat4 b Right hand operand
-- @treturn mat4 out
function mat4.mul(out, a, b)
	tm4[1]  = a[1]  * b[1] + a[2]  * b[5] + a[3]  * b[9]  + a[4]  * b[13]
	tm4[2]  = a[1]  * b[2] + a[2]  * b[6] + a[3]  * b[10] + a[4]  * b[14]
	tm4[3]  = a[1]  * b[3] + a[2]  * b[7] + a[3]  * b[11] + a[4]  * b[15]
	tm4[4]  = a[1]  * b[4] + a[2]  * b[8] + a[3]  * b[12] + a[4]  * b[16]
	tm4[5]  = a[5]  * b[1] + a[6]  * b[5] + a[7]  * b[9]  + a[8]  * b[13]
	tm4[6]  = a[5]  * b[2] + a[6]  * b[6] + a[7]  * b[10] + a[8]  * b[14]
	tm4[7]  = a[5]  * b[3] + a[6]  * b[7] + a[7]  * b[11] + a[8]  * b[15]
	tm4[8]  = a[5]  * b[4] + a[6]  * b[8] + a[7]  * b[12] + a[8]  * b[16]
	tm4[9]  = a[9]  * b[1] + a[10] * b[5] + a[11] * b[9]  + a[12] * b[13]
	tm4[10] = a[9]  * b[2] + a[10] * b[6] + a[11] * b[10] + a[12] * b[14]
	tm4[11] = a[9]  * b[3] + a[10] * b[7] + a[11] * b[11] + a[12] * b[15]
	tm4[12] = a[9]  * b[4] + a[10] * b[8] + a[11] * b[12] + a[12] * b[16]
	tm4[13] = a[13] * b[1] + a[14] * b[5] + a[15] * b[9]  + a[16] * b[13]
	tm4[14] = a[13] * b[2] + a[14] * b[6] + a[15] * b[10] + a[16] * b[14]
	tm4[15] = a[13] * b[3] + a[14] * b[7] + a[15] * b[11] + a[16] * b[15]
	tm4[16] = a[13] * b[4] + a[14] * b[8] + a[15] * b[12] + a[16] * b[16]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	return out
end

--- Multiply a matrix and a vec4.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Left hand operand
-- @tparam table b Right hand operand
-- @treturn mat4 out
function mat4.mul_vec4(out, a, b)
	tv4[1] = b[1] * a[1] + b[2] * a[5] + b [3] * a[9]  + b[4] * a[13]
	tv4[2] = b[1] * a[2] + b[2] * a[6] + b [3] * a[10] + b[4] * a[14]
	tv4[3] = b[1] * a[3] + b[2] * a[7] + b [3] * a[11] + b[4] * a[15]
	tv4[4] = b[1] * a[4] + b[2] * a[8] + b [3] * a[12] + b[4] * a[16]

	for i=1, 4 do
		out[i] = tv4[i]
	end

	return out
end

--- Invert a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to invert
-- @treturn mat4 out
function mat4.invert(out, a)
	tm4[1]  =  a[6] * a[11] * a[16] - a[6] * a[12] * a[15] - a[10] * a[7] * a[16] + a[10] * a[8] * a[15] + a[14] * a[7] * a[12] - a[14] * a[8] * a[11]
	tm4[2]  = -a[2] * a[11] * a[16] + a[2] * a[12] * a[15] + a[10] * a[3] * a[16] - a[10] * a[4] * a[15] - a[14] * a[3] * a[12] + a[14] * a[4] * a[11]
	tm4[3]  =  a[2] * a[7]  * a[16] - a[2] * a[8]  * a[15] - a[6]  * a[3] * a[16] + a[6]  * a[4] * a[15] + a[14] * a[3] * a[8]  - a[14] * a[4] * a[7]
	tm4[4]  = -a[2] * a[7]  * a[12] + a[2] * a[8]  * a[11] + a[6]  * a[3] * a[12] - a[6]  * a[4] * a[11] - a[10] * a[3] * a[8]  + a[10] * a[4] * a[7]
	tm4[5]  = -a[5] * a[11] * a[16] + a[5] * a[12] * a[15] + a[9]  * a[7] * a[16] - a[9]  * a[8] * a[15] - a[13] * a[7] * a[12] + a[13] * a[8] * a[11]
	tm4[6]  =  a[1] * a[11] * a[16] - a[1] * a[12] * a[15] - a[9]  * a[3] * a[16] + a[9]  * a[4] * a[15] + a[13] * a[3] * a[12] - a[13] * a[4] * a[11]
	tm4[7]  = -a[1] * a[7]  * a[16] + a[1] * a[8]  * a[15] + a[5]  * a[3] * a[16] - a[5]  * a[4] * a[15] - a[13] * a[3] * a[8]  + a[13] * a[4] * a[7]
	tm4[8]  =  a[1] * a[7]  * a[12] - a[1] * a[8]  * a[11] - a[5]  * a[3] * a[12] + a[5]  * a[4] * a[11] + a[9]  * a[3] * a[8]  - a[9]  * a[4] * a[7]
	tm4[9]  =  a[5] * a[10] * a[16] - a[5] * a[12] * a[14] - a[9]  * a[6] * a[16] + a[9]  * a[8] * a[14] + a[13] * a[6] * a[12] - a[13] * a[8] * a[10]
	tm4[10] = -a[1] * a[10] * a[16] + a[1] * a[12] * a[14] + a[9]  * a[2] * a[16] - a[9]  * a[4] * a[14] - a[13] * a[2] * a[12] + a[13] * a[4] * a[10]
	tm4[11] =  a[1] * a[6]  * a[16] - a[1] * a[8]  * a[14] - a[5]  * a[2] * a[16] + a[5]  * a[4] * a[14] + a[13] * a[2] * a[8]  - a[13] * a[4] * a[6]
	tm4[12] = -a[1] * a[6]  * a[12] + a[1] * a[8]  * a[10] + a[5]  * a[2] * a[12] - a[5]  * a[4] * a[10] - a[9]  * a[2] * a[8]  + a[9]  * a[4] * a[6]
	tm4[13] = -a[5] * a[10] * a[15] + a[5] * a[11] * a[14] + a[9]  * a[6] * a[15] - a[9]  * a[7] * a[14] - a[13] * a[6] * a[11] + a[13] * a[7] * a[10]
	tm4[14] =  a[1] * a[10] * a[15] - a[1] * a[11] * a[14] - a[9]  * a[2] * a[15] + a[9]  * a[3] * a[14] + a[13] * a[2] * a[11] - a[13] * a[3] * a[10]
	tm4[15] = -a[1] * a[6]  * a[15] + a[1] * a[7]  * a[14] + a[5]  * a[2] * a[15] - a[5]  * a[3] * a[14] - a[13] * a[2] * a[7]  + a[13] * a[3] * a[6]
	tm4[16] =  a[1] * a[6]  * a[11] - a[1] * a[7]  * a[10] - a[5]  * a[2] * a[11] + a[5]  * a[3] * a[10] + a[9]  * a[2] * a[7]  - a[9]  * a[3] * a[6]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	local det = a[1] * out[1] + a[2] * out[5] + a[3] * out[9] + a[4] * out[13]

	if det == 0 then return a end

	det = 1 / det

	for i = 1, 16 do
		out[i] = out[i] * det
	end

	return out
end

--- Scale a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to scale
-- @tparam vec3 s Scalar
-- @treturn mat4 out
function mat4.scale(out, a, s)
	identity(tmp)
	tmp[1]  = s.x
	tmp[6]  = s.y
	tmp[11] = s.z

	return out:mul(tmp, a)
end

--- Rotate a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to rotate
-- @tparam number angle Angle to rotate by (in radians)
-- @tparam vec3 axis Axis to rotate on
-- @treturn mat4 out
function mat4.rotate(out, a, angle, axis)
	if type(angle) == "table" or type(angle) == "cdata" then
		angle, axis = angle:to_angle_axis()
	end

	local l = axis:len()

	if l == 0 then
		return a
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	identity(tmp)
	tmp[1]  = x * x * (1 - c) + c
	tmp[2]  = y * x * (1 - c) + z * s
	tmp[3]  = x * z * (1 - c) - y * s
	tmp[5]  = x * y * (1 - c) - z * s
	tmp[6]  = y * y * (1 - c) + c
 	tmp[7]  = y * z * (1 - c) + x * s
	tmp[9]  = x * z * (1 - c) + y * s
	tmp[10] = y * z * (1 - c) - x * s
	tmp[11] = z * z * (1 - c) + c

	return out:mul(tmp, a)
end

--- Translate a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to translate
-- @tparam vec3 t Translation vector
-- @treturn mat4 out
function mat4.translate(out, a, t)
	identity(tmp)
	tmp[13] = t.x
	tmp[14] = t.y
	tmp[15] = t.z

	return out:mul(tmp, a)
end

--- Shear a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to translate
-- @tparam number yx
-- @tparam number zx
-- @tparam number xy
-- @tparam number zy
-- @tparam number xz
-- @tparam number yz
-- @treturn mat4 out
function mat4.shear(out, a, yx, zx, xy, zy, xz, yz)
	identity(tmp)
	tmp[2]  = yx or 0
	tmp[3]  = zx or 0
	tmp[5]  = xy or 0
	tmp[7]  = zy or 0
	tmp[9]  = xz or 0
	tmp[10] = yz or 0

	return out:mul(tmp, a)
end

--- Reflect a matrix across a plane.
-- @tparam mat4 Matrix to store the result
-- @tparam a Matrix to reflect
-- @tparam vec3 position A point on the plane
-- @tparam vec3 normal The (normalized!) normal vector of the plane
function mat4.reflect(out, a, position, normal)
	local nx, ny, nz = normal:unpack()
	local d = -position:dot(normal)
	tmp[1] = 1 - 2 * nx ^ 2
	tmp[2] = 2 * nx * ny
	tmp[3] = -2 * nx * nz
	tmp[4] = 0
	tmp[5] = -2 * nx * ny
	tmp[6] = 1 - 2 * ny ^ 2
	tmp[7] = -2 * ny * nz
	tmp[8] = 0
	tmp[9] = -2 * nx * nz
	tmp[10] = -2 * ny * nz
	tmp[11] = 1 - 2 * nz ^ 2
	tmp[12] = 0
	tmp[13] = -2 * nx * d
	tmp[14] = -2 * ny * d
	tmp[15] = -2 * nz * d
	tmp[16] = 1

	return out:mul(tmp, a)
end

--- Transform matrix to look at a point.
-- @tparam mat4 out Matrix to store result
-- @tparam mat4 a Matrix to transform
-- @tparam vec3 eye Location of viewer's view plane
-- @tparam vec3 center Location of object to view
-- @tparam vec3 up Up direction
-- @treturn mat4 out
function mat4.look_at(out, a, eye, look_at, up)
	local z_axis = (eye - look_at):normalize()
	local x_axis = up:cross(z_axis):normalize()
	local y_axis = z_axis:cross(x_axis)
	out[1] = x_axis.x
	out[2] = y_axis.x
	out[3] = z_axis.x
	out[4] = 0
	out[5] = x_axis.y
	out[6] = y_axis.y
	out[7] = z_axis.y
	out[8] = 0
	out[9] = x_axis.z
	out[10] = y_axis.z
	out[11] = z_axis.z
	out[12] = 0
	out[13] = 0
	out[14] = 0
	out[15] = 0
	out[16] = 1

  return out
end

--- Transpose a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to transpose
-- @treturn mat4 out
function mat4.transpose(out, a)
	tm4[1]  = a[1]
	tm4[2]  = a[5]
	tm4[3]  = a[9]
	tm4[4]  = a[13]
	tm4[5]  = a[2]
	tm4[6]  = a[6]
	tm4[7]  = a[10]
	tm4[8]  = a[14]
	tm4[9]  = a[3]
	tm4[10] = a[7]
	tm4[11] = a[11]
	tm4[12] = a[15]
	tm4[13] = a[4]
	tm4[14] = a[8]
	tm4[15] = a[12]
	tm4[16] = a[16]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	return out
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L518
--- Project a matrix from world space to screen space.
-- @tparam vec3 obj Object position in world space
-- @tparam mat4 view View matrix
-- @tparam mat4 projection Projection matrix
-- @tparam table viewport XYWH of viewport
-- @treturn vec3 win
function mat4.project(obj, view, projection, viewport)
	local position = { obj.x, obj.y, obj.z, 1 }

	mat4.mul_vec4(position, view,       position)
	mat4.mul_vec4(position, projection, position)

	position[1] = position[1] / position[4] * 0.5 + 0.5
	position[2] = position[2] / position[4] * 0.5 + 0.5
	position[3] = position[3] / position[4] * 0.5 + 0.5

	position[1] = position[1] * viewport[3] + viewport[1]
	position[2] = position[2] * viewport[4] + viewport[2]

	return vec3(position[1], position[2], position[3])
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L544
--- Unproject a matrix from screen space to world space.
-- @tparam vec3 win Object position in screen space
-- @tparam mat4 view View matrix
-- @tparam mat4 projection Projection matrix
-- @tparam table viewport XYWH of viewport
-- @treturn vec3 obj
function mat4.unproject(win, view, projection, viewport)
	local position = { win.x, win.y, win.z, 1 }

	position[1] = (position[1] - viewport[1]) / viewport[3]
	position[2] = (position[2] - viewport[2]) / viewport[4]

	position[1] = position[1] * 2 - 1
	position[2] = position[2] * 2 - 1
	position[3] = position[3] * 2 - 1

	tmp:mul(projection, view):invert(tmp)
	mat4.mul_vec4(position, tmp, position)

	position[1] = position[1] / position[4]
	position[2] = position[2] / position[4]
	position[3] = position[3] / position[4]

	return vec3(position[1], position[2], position[3])
end

--- Return a boolean showing if a table is or is not a mat4.
-- @tparam mat4 a Matrix to be tested
-- @treturn boolean is_mat4
function mat4.is_mat4(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_mat4", a)
	end

	if type(a) ~= "table" then
		return false
	end

	for i = 1, 16 do
		if type(a[i]) ~= "number" then
			return false
		end
	end

	return true
end

--- Return a formatted string.
-- @tparam mat4 a Matrix to be turned into a string
-- @treturn string formatted
function mat4.to_string(a)
	local str = "[ "
	for i = 1, 16 do
		str = str .. string.format("%+0.3f", a[i])
		if i < 16 then
			str = str .. ", "
		end
	end
	str = str .. " ]"
	return str
end

--- Convert a matrix to vec4s.
-- @tparam mat4 a Matrix to be converted
-- @treturn table vec4s
function mat4.to_vec4s(a)
	return {
		{ a[1],  a[2],  a[3],  a[4]  },
		{ a[5],  a[6],  a[7],  a[8]  },
		{ a[9],  a[10], a[11], a[12] },
		{ a[13], a[14], a[15], a[16] }
	}
end

-- http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
--- Convert a matrix to a quaternion.
-- @tparam mat4 a Matrix to be converted
-- @treturn quat out
function mat4.to_quat(a)
	identity(tmp):transpose(a)

	local w     = sqrt(1 + tmp[1] + tmp[6] + tmp[11]) / 2
	local scale = w * 4
	local q     = quat.new(
		tmp[10] - tmp[7] / scale,
		tmp[3]  - tmp[9] / scale,
		tmp[5]  - tmp[2] / scale,
		w
	)

	return q:normalize(q)
end

-- http://www.crownandcutlass.com/features/technicaldetails/frustum.html
--- Convert a matrix to a frustum.
-- @tparam mat4 a Matrix to be converted (projection * view)
-- @tparam boolean infinite Infinite removes the far plane
-- @treturn frustum out
function mat4.to_frustum(a, infinite)
	local t
	local frustum = {}

	-- Extract the LEFT plane
	frustum.left   = {}
	frustum.left.a = a[4]  + a[1]
	frustum.left.b = a[8]  + a[5]
	frustum.left.c = a[12] + a[9]
	frustum.left.d = a[16] + a[13]

	-- Normalize the result
	t = sqrt(frustum.left.a * frustum.left.a + frustum.left.b * frustum.left.b + frustum.left.c * frustum.left.c)
	frustum.left.a = frustum.left.a / t
	frustum.left.b = frustum.left.b / t
	frustum.left.c = frustum.left.c / t
	frustum.left.d = frustum.left.d / t

	-- Extract the RIGHT plane
	frustum.right   = {}
	frustum.right.a = a[4]  - a[1]
	frustum.right.b = a[8]  - a[5]
	frustum.right.c = a[12] - a[9]
	frustum.right.d = a[16] - a[13]

	-- Normalize the result
	t = sqrt(frustum.right.a * frustum.right.a + frustum.right.b * frustum.right.b + frustum.right.c * frustum.right.c)
	frustum.right.a = frustum.right.a / t
	frustum.right.b = frustum.right.b / t
	frustum.right.c = frustum.right.c / t
	frustum.right.d = frustum.right.d / t

	-- Extract the BOTTOM plane
	frustum.bottom   = {}
	frustum.bottom.a = a[4]  + a[2]
	frustum.bottom.b = a[8]  + a[6]
	frustum.bottom.c = a[12] + a[10]
	frustum.bottom.d = a[16] + a[14]

	-- Normalize the result
	t = sqrt(frustum.bottom.a * frustum.bottom.a + frustum.bottom.b * frustum.bottom.b + frustum.bottom.c * frustum.bottom.c)
	frustum.bottom.a = frustum.bottom.a / t
	frustum.bottom.b = frustum.bottom.b / t
	frustum.bottom.c = frustum.bottom.c / t
	frustum.bottom.d = frustum.bottom.d / t

	-- Extract the TOP plane
	frustum.top   = {}
	frustum.top.a = a[4]  - a[2]
	frustum.top.b = a[8]  - a[6]
	frustum.top.c = a[12] - a[10]
	frustum.top.d = a[16] - a[14]

	-- Normalize the result
	t = sqrt(frustum.top.a * frustum.top.a + frustum.top.b * frustum.top.b + frustum.top.c * frustum.top.c)
	frustum.top.a = frustum.top.a / t
	frustum.top.b = frustum.top.b / t
	frustum.top.c = frustum.top.c / t
	frustum.top.d = frustum.top.d / t

	-- Extract the NEAR plane
	frustum.near   = {}
	frustum.near.a = a[4]  + a[3]
	frustum.near.b = a[8]  + a[7]
	frustum.near.c = a[12] + a[11]
	frustum.near.d = a[16] + a[15]

	-- Normalize the result
	t = sqrt(frustum.near.a * frustum.near.a + frustum.near.b * frustum.near.b + frustum.near.c * frustum.near.c)
	frustum.near.a = frustum.near.a / t
	frustum.near.b = frustum.near.b / t
	frustum.near.c = frustum.near.c / t
	frustum.near.d = frustum.near.d / t

	if not infinite then
		-- Extract the FAR plane
		frustum.far   = {}
		frustum.far.a = a[4]  - a[3]
		frustum.far.b = a[8]  - a[7]
		frustum.far.c = a[12] - a[11]
		frustum.far.d = a[16] - a[15]

		-- Normalize the result
		t = sqrt(frustum.far.a * frustum.far.a + frustum.far.b * frustum.far.b + frustum.far.c * frustum.far.c)
		frustum.far.a = frustum.far.a / t
		frustum.far.b = frustum.far.b / t
		frustum.far.c = frustum.far.c / t
		frustum.far.d = frustum.far.d / t
	end

	return frustum
end

function mat4_mt.__index(t, k)
	if type(t) == "cdata" then
		if type(k) == "number" then
			return t._m[k-1]
		end
	end

	return rawget(mat4, k)
end

function mat4_mt.__newindex(t, k, v)
	if type(t) == "cdata" then
		if type(k) == "number" then
			t._m[k-1] = v
		end
	end
end

mat4_mt.__tostring = mat4.to_string

function mat4_mt.__call(_, a)
	return mat4.new(a)
end

function mat4_mt.__unm(a)
	return new():invert(a)
end

function mat4_mt.__eq(a, b)
	if not mat4.is_mat4(a) or not mat4.is_mat4(b) then
		return false
	end

	for i = 1, 16 do
		if not utils.tolerance(b[i]-a[i], constants.FLT_EPSILON) then
			return false
		end
	end

	return true
end

function mat4_mt.__mul(a, b)
	assert(mat4.is_mat4(a), "__mul: Wrong argument type for left hand operand. (<cpml.mat4> expected)")

	if vec3.is_vec3(b) then
		return vec3(mat4.mul_vec4({}, a, { b.x, b.y, b.z, 1 }))
	end

	assert(mat4.is_mat4(b) or #b == 4, "__mul: Wrong argument type for right hand operand. (<cpml.mat4> or table #4 expected)")

	if mat4.is_mat4(b) then
		return new():mul(a, b)
	end

	return mat4.mul_vec4({}, a, b)
end

if status then
	ffi.metatype(new, mat4_mt)
end

return setmetatable({}, mat4_mt)
