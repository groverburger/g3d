--- A 2 component bounding box.
-- @module bound2

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec2    = require(modules .. "vec2")

local bound2    = {}
local bound2_mt = {}

-- Private constructor.
local function new(min, max)
	return setmetatable({
		min=min, -- min: vec2, minimum value for each component 
		max=max, -- max: vec2, maximum value for each component 
	}, bound2_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { cpml_vec2 min, max; } cpml_bound2;"
		new = ffi.typeof("cpml_bound2")
	end
end

bound2.zero = new(vec2.zero, vec2.zero)

--- The public constructor.
-- @param min Can be of two types: </br>
-- vec2 min, minimum value for each component
-- nil Create bound at single point 0,0
-- @tparam vec2 max, maximum value for each component
-- @treturn bound2 out
function bound2.new(min, max)
	if min and max then
		return new(min:clone(), max:clone())
	elseif min or max then
		error("Unexpected nil argument to bound2.new")
	else
		return new(vec2.zero, vec2.zero)
	end
end

--- Clone a bound.
-- @tparam bound2 a bound to be cloned
-- @treturn bound2 out
function bound2.clone(a)
	return new(a.min, a.max)
end

--- Construct a bound covering one or two points 
-- @tparam vec2 a Any vector
-- @tparam vec2 b Any second vector (optional)
-- @treturn vec2 Minimum bound containing the given points
function bound2.at(a, b) -- "bounded by". b may be nil
	if b then
		return bound2.new(a,b):check()
	else
		return bound2.zero:with_center(a)
	end
end

--- Get size of bounding box as a vector 
-- @tparam bound2 a bound
-- @treturn vec2 Vector spanning min to max points
function bound2.size(a)
	return a.max - a.min
end

--- Resize bounding box from minimum corner
-- @tparam bound2 a bound
-- @tparam vec2 new size
-- @treturn bound2 resized bound
function bound2.with_size(a, size)
	return bound2.new(a.min, a.min + size)
end

--- Get half-size of bounding box as a vector. A more correct term for this is probably "apothem"
-- @tparam bound2 a bound
-- @treturn vec2 Vector spanning center to max point
function bound2.radius(a)
	return a:size()/2
end

--- Get center of bounding box
-- @tparam bound2 a bound
-- @treturn bound2 Point in center of bound
function bound2.center(a)
	return (a.min + a.max)/2
end

--- Move bounding box to new center
-- @tparam bound2 a bound
-- @tparam vec2 new center
-- @treturn bound2 Bound with same size as input but different center
function bound2.with_center(a, center)
	return bound2.offset(a, center - a:center())
end

--- Resize bounding box from center
-- @tparam bound2 a bound
-- @tparam vec2 new size
-- @treturn bound2 resized bound
function bound2.with_size_centered(a, size)
	local center = a:center()
	local rad = size/2
	return bound2.new(center - rad, center + rad)
end

--- Convert possibly-invalid bounding box to valid one
-- @tparam bound2 a bound
-- @treturn bound2 bound with all components corrected for min-max property
function bound2.check(a)
	if a.min.x > a.max.x or a.min.y > a.max.y then
		return bound2.new(vec2.component_min(a.min, a.max), vec2.component_max(a.min, a.max))
	end
	return a
end

--- Shrink bounding box with fixed margin
-- @tparam bound2 a bound
-- @tparam vec2 a margin
-- @treturn bound2 bound with margin subtracted from all edges. May not be valid, consider calling check()
function bound2.inset(a, v)
	return bound2.new(a.min + v, a.max - v)
end

--- Expand bounding box with fixed margin
-- @tparam bound2 a bound
-- @tparam vec2 a margin
-- @treturn bound2 bound with margin added to all edges. May not be valid, consider calling check()
function bound2.outset(a, v)
	return bound2.new(a.min - v, a.max + v)
end

--- Offset bounding box
-- @tparam bound2 a bound
-- @tparam vec2 offset
-- @treturn bound2 bound with same size, but position moved by offset
function bound2.offset(a, v)
	return bound2.new(a.min + v, a.max + v)
end

--- Test if point in bound
-- @tparam bound2 a bound
-- @tparam vec2 point to test
-- @treturn boolean true if point in bounding box
function bound2.contains(a, v)
	return a.min.x <= v.x and a.min.y <= v.y and a.min.z <= v.z
	   and a.max.x >= v.x and a.max.y >= v.y and a.max.z >= v.z
end

bound2_mt.__index    = bound2
bound2_mt.__tostring = bound2.to_string

function bound2_mt.__call(_, a, b)
	return bound2.new(a, b)
end

if status then
	ffi.metatype(new, bound2_mt)
end

return setmetatable({}, bound2_mt)
