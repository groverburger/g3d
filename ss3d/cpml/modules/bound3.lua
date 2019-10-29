--- A 3-component axis-aligned bounding box.
-- @module bound3

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3    = require(modules .. "vec3")

local bound3    = {}
local bound3_mt = {}

-- Private constructor.
local function new(min, max)
	return setmetatable({
		min=min, -- min: vec3, minimum value for each component 
		max=max  -- max: vec3, maximum value for each component
	}, bound3_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { cpml_vec3 min, max; } cpml_bound3;"
		new = ffi.typeof("cpml_bound3")
	end
end

bound3.zero = new(vec3.zero, vec3.zero)

--- The public constructor.
-- @param min Can be of two types: </br>
-- vec3 min, minimum value for each component
-- nil Create bound at single point 0,0,0
-- @tparam vec3 max, maximum value for each component
-- @treturn bound3 out
function bound3.new(min, max)
	if min and max then
		return new(min:clone(), max:clone())
	elseif min or max then
		error("Unexpected nil argument to bound3.new")
	else
		return new(vec3.zero, vec3.zero)
	end
end

--- Clone a bound.
-- @tparam bound3 a bound to be cloned
-- @treturn bound3 out
function bound3.clone(a)
	return new(a.min, a.max)
end

--- Construct a bound covering one or two points 
-- @tparam vec3 a Any vector
-- @tparam vec3 b Any second vector (optional)
-- @treturn vec3 Minimum bound containing the given points
function bound3.at(a, b) -- "bounded by". b may be nil
	if b then
		return bound3.new(a,b):check()
	else
		return bound3.zero:with_center(a)
	end
end

--- Get size of bounding box as a vector 
-- @tparam bound3 a bound
-- @treturn vec3 Vector spanning min to max points
function bound3.size(a)
	return a.max - a.min
end

--- Resize bounding box from minimum corner
-- @tparam bound3 a bound
-- @tparam vec3 new size
-- @treturn bound3 resized bound
function bound3.with_size(a, size)
	return bound3.new(a.min, a.min + size)
end

--- Get half-size of bounding box as a vector. A more correct term for this is probably "apothem"
-- @tparam bound3 a bound
-- @treturn vec3 Vector spanning center to max point
function bound3.radius(a)
	return a:size()/2
end

--- Get center of bounding box
-- @tparam bound3 a bound
-- @treturn bound3 Point in center of bound
function bound3.center(a)
	return (a.min + a.max)/2
end

--- Move bounding box to new center
-- @tparam bound3 a bound
-- @tparam vec3 new center
-- @treturn bound3 Bound with same size as input but different center
function bound3.with_center(a, center)
	return bound3.offset(a, center - a:center())
end

--- Resize bounding box from center
-- @tparam bound3 a bound
-- @tparam vec3 new size
-- @treturn bound3 resized bound
function bound3.with_size_centered(a, size)
	local center = a:center()
	local rad = size/2
	return bound3.new(center - rad, center + rad)
end

--- Convert possibly-invalid bounding box to valid one
-- @tparam bound3 a bound
-- @treturn bound3 bound with all components corrected for min-max property
function bound3.check(a)
	if a.min.x > a.max.x or a.min.y > a.max.y or a.min.z > a.max.z then
		return bound3.new(vec3.component_min(a.min, a.max), vec3.component_max(a.min, a.max))
	end
	return a
end

--- Shrink bounding box with fixed margin
-- @tparam bound3 a bound
-- @tparam vec3 a margin
-- @treturn bound3 bound with margin subtracted from all edges. May not be valid, consider calling check()
function bound3.inset(a, v)
	return bound3.new(a.min + v, a.max - v)
end

--- Expand bounding box with fixed margin
-- @tparam bound3 a bound
-- @tparam vec3 a margin
-- @treturn bound3 bound with margin added to all edges. May not be valid, consider calling check()
function bound3.outset(a, v)
	return bound3.new(a.min - v, a.max + v)
end

--- Offset bounding box
-- @tparam bound3 a bound
-- @tparam vec3 offset
-- @treturn bound3 bound with same size, but position moved by offset
function bound3.offset(a, v)
	return bound3.new(a.min + v, a.max + v)
end

--- Test if point in bound
-- @tparam bound3 a bound
-- @tparam vec3 point to test
-- @treturn boolean true if point in bounding box
function bound3.contains(a, v)
	return a.min.x <= v.x and a.min.y <= v.y and a.min.z <= v.z
	   and a.max.x >= v.x and a.max.y >= v.y and a.max.z >= v.z
end

bound3_mt.__index    = bound3
bound3_mt.__tostring = bound3.to_string

function bound3_mt.__call(_, a, b)
	return bound3.new(a, b)
end

if status then
	ffi.metatype(new, bound3_mt)
end

return setmetatable({}, bound3_mt)
