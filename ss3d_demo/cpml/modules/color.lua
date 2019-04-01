--- Color utilities
-- @module color

local modules  = (...):gsub('%.[^%.]+$', '') .. "."
local utils    = require(modules .. "utils")
local color    = {}
local color_mt = {}

local function new(r, g, b, a)
	local c = { r, g, b, a }
	c._c = c
	return setmetatable(c, color)
end

-- HSV utilities (adapted from http://www.cs.rit.edu/~ncs/color/t_convert.html)
-- hsv_to_color(hsv)
-- Converts a set of HSV values to a color. hsv is a table.
-- See also: hsv(h, s, v)
local function hsv_to_color(hsv)
	local i
	local f, q, p, t
	local h, s, v
	local a = hsv[4] or 255
	s = hsv[2]
	v = hsv[3]

	if s == 0 then
		return new(v, v, v, a)
	end

	h = hsv[1] / 60

	i = math.floor(h)
	f = h - i
	p = v * (1-s)
	q = v * (1-s*f)
	t = v * (1-s*(1-f))

	if     i == 0 then return new(v, t, p, a)
	elseif i == 1 then return new(q, v, p, a)
	elseif i == 2 then return new(p, v, t, a)
	elseif i == 3 then return new(p, q, v, a)
	elseif i == 4 then return new(t, p, v, a)
	else               return new(v, p, q, a)
	end
end

-- color_to_hsv(c)
-- Takes in a normal color and returns a table with the HSV values.
local function color_to_hsv(c)
	local r = c[1]
	local g = c[2]
	local b = c[3]
	local a = c[4] or 255
	local h, s, v

	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	v = max

	local delta = max - min

	-- black, nothing else is really possible here.
	if min == 0 and max == 0 then
		return { 0, 0, 0, a }
	end

	if max ~= 0 then
		s = delta / max
	else
		-- r = g = b = 0 s = 0, v is undefined
		s = 0
		h = -1
		return { h, s, v, 255 }
	end

	if r == max then
		h = ( g - b ) / delta     -- yellow/magenta
	elseif g == max then
		h = 2 + ( b - r ) / delta -- cyan/yellow
	else
		h = 4 + ( r - g ) / delta -- magenta/cyan
	end

	h = h * 60 -- degrees

	if h < 0 then
		h = h + 360
	end

	return { h, s, v, a }
end

--- The public constructor.
-- @param x Can be of three types: </br>
-- number red component 0-255
-- table {r, g, b, a}
-- nil for {0,0,0,0}
-- @tparam number g Green component 0-255
-- @tparam number b Blue component 0-255
-- @tparam number a Alpha component 0-255
-- @treturn color out
function color.new(r, g, b, a)
	-- number, number, number, number
	if r and g and b and a then
		assert(type(r) == "number", "new: Wrong argument type for r (<number> expected)")
		assert(type(g) == "number", "new: Wrong argument type for g (<number> expected)")
		assert(type(b) == "number", "new: Wrong argument type for b (<number> expected)")
		assert(type(a) == "number", "new: Wrong argument type for a (<number> expected)")

		return new(r, g, b, a)

	-- {r, g, b, a}
	elseif type(r) == "table" then
		local rr, gg, bb, aa = r[1], r[2], r[3], r[4]
		assert(type(rr) == "number", "new: Wrong argument type for r (<number> expected)")
		assert(type(gg) == "number", "new: Wrong argument type for g (<number> expected)")
		assert(type(bb) == "number", "new: Wrong argument type for b (<number> expected)")
		assert(type(aa) == "number", "new: Wrong argument type for a (<number> expected)")

		return new(rr, gg, bb, aa)
	end

	return new(0, 0, 0, 0)
end

--- Convert hue,saturation,value table to color object.
-- @tparam table hsva {hue 0-359, saturation 0-1, value 0-1, alpha 0-255}
-- @treturn color out
color.hsv_to_color_table = hsv_to_color

--- Convert color to hue,saturation,value table
-- @tparam color in
-- @treturn table hsva {hue 0-359, saturation 0-1, value 0-1, alpha 0-255}
color.color_to_hsv_table = color_to_hsv

--- Convert hue,saturation,value to color object.
-- @tparam number h hue 0-359
-- @tparam number s saturation 0-1
-- @tparam number v value 0-1
-- @treturn color out
function color.from_hsv(h, s, v)
	return hsv_to_color { h, s, v }
end

--- Convert hue,saturation,value to color object.
-- @tparam number h hue 0-359
-- @tparam number s saturation 0-1
-- @tparam number v value 0-1
-- @tparam number a alpha 0-255
-- @treturn color out
function color.from_hsva(h, s, v, a)
	return hsv_to_color { h, s, v, a }
end

--- Invert a color.
-- @tparam color to invert
-- @treturn color out
function color.invert(c)
	return new(255 - c[1], 255 - c[2], 255 - c[3], c[4])
end

--- Lighten a color by a component-wise fixed amount (alpha unchanged)
-- @tparam color to lighten
-- @tparam number amount to increase each component by, 0-255 scale
-- @treturn color out
function color.lighten(c, v)
	return new(
		utils.clamp(c[1] + v * 255, 0, 255),
		utils.clamp(c[2] + v * 255, 0, 255),
		utils.clamp(c[3] + v * 255, 0, 255),
		c[4]
	)
end

function color.lerp(a, b, s)
	return a + s * (b - a)
end

--- Darken a color by a component-wise fixed amount (alpha unchanged)
-- @tparam color to darken
-- @tparam number amount to decrease each component by, 0-255 scale
-- @treturn color out
function color.darken(c, v)
	return new(
		utils.clamp(c[1] - v * 255, 0, 255),
		utils.clamp(c[2] - v * 255, 0, 255),
		utils.clamp(c[3] - v * 255, 0, 255),
		c[4]
	)
end

--- Multiply a color's components by a value (alpha unchanged)
-- @tparam color to multiply
-- @tparam number to multiply each component by
-- @treturn color out
function color.multiply(c, v)
	local t = color.new()
	for i = 1, 3 do
		t[i] = c[i] * v
	end

	t[4] = c[4]
	return t
end

-- directly set alpha channel
-- @tparam color to alter
-- @tparam number new alpha 0-255
-- @treturn color out
function color.alpha(c, v)
	local t = color.new()
	for i = 1, 3 do
		t[i] = c[i]
	end

	t[4] = v * 255
	return t
end

--- Multiply a color's alpha by a value
-- @tparam color to multiply
-- @tparam number to multiply alpha by
-- @treturn color out
function color.opacity(c, v)
	local t = color.new()
	for i = 1, 3 do
		t[i] = c[i]
	end

	t[4] = c[4] * v
	return t
end

--- Set a color's hue (saturation, value, alpha unchanged)
-- @tparam color to alter
-- @tparam hue to set 0-359
-- @treturn color out
function color.hue(col, hue)
	local c = color_to_hsv(col)
	c[1] = (hue + 360) % 360
	return hsv_to_color(c)
end

--- Set a color's saturation (hue, value, alpha unchanged)
-- @tparam color to alter
-- @tparam hue to set 0-359
-- @treturn color out
function color.saturation(col, percent)
	local c = color_to_hsv(col)
	c[2] = utils.clamp(percent, 0, 1)
	return hsv_to_color(c)
end

--- Set a color's value (saturation, hue, alpha unchanged)
-- @tparam color to alter
-- @tparam hue to set 0-359
-- @treturn color out
function color.value(col, percent)
	local c = color_to_hsv(col)
	c[3] = utils.clamp(percent, 0, 1)
	return hsv_to_color(c)
end

-- http://en.wikipedia.org/wiki/SRGB#The_reverse_transformation
function color.gamma_to_linear(r, g, b, a)
	local function convert(c)
		if c > 1.0 then
			return 1.0
		elseif c < 0.0 then
			return 0.0
		elseif c <= 0.04045 then
			return c / 12.92
		else
			return math.pow((c + 0.055) / 1.055, 2.4)
		end
	end

	if type(r) == "table" then
		local c = {}
		for i = 1, 3 do
			c[i] = convert(r[i] / 255) * 255
		end

		c[4] = convert(r[4] / 255) * 255
		return c
	else
		return convert(r / 255) * 255, convert(g / 255) * 255, convert(b / 255) * 255, a or 255
	end
end

-- http://en.wikipedia.org/wiki/SRGB#The_forward_transformation_.28CIE_xyY_or_CIE_XYZ_to_sRGB.29
function color.linear_to_gamma(r, g, b, a)
	local function convert(c)
		if c > 1.0 then
			return 1.0
		elseif c < 0.0 then
			return 0.0
		elseif c < 0.0031308 then
			return c * 12.92
		else
			return 1.055 * math.pow(c, 0.41666) - 0.055
		end
	end

	if type(r) == "table" then
		local c = {}
		for i = 1, 3 do
			c[i] = convert(r[i] / 255) * 255
		end

		c[4] = convert(r[4] / 255) * 255
		return c
	else
		return convert(r / 255) * 255, convert(g / 255) * 255, convert(b / 255) * 255, a or 255
	end
end

--- Check if color is valid
-- @tparam color to test
-- @treturn boolean is color
function color.is_color(a)
	if type(a) ~= "table" then
		return false
	end

	for i = 1, 4 do
		if type(a[i]) ~= "number" then
			return false
		end
	end

	return true
end

--- Return a formatted string.
-- @tparam color a color to be turned into a string
-- @treturn string formatted
function color.to_string(a)
	return string.format("[ %3.0f, %3.0f, %3.0f, %3.0f ]", a[1], a[2], a[3], a[4])
end

function color_mt.__index(t, k)
	if type(t) == "cdata" then
		if type(k) == "number" then
			return t._c[k-1]
		end
	end

	return rawget(color, k)
end

function color_mt.__newindex(t, k, v)
	if type(t) == "cdata" then
		if type(k) == "number" then
			t._c[k-1] = v
		end
	end
end

color_mt.__tostring = color.to_string

function color_mt.__call(_, r, g, b, a)
	return color.new(r, g, b, a)
end

function color_mt.__add(a, b)
	return new(a[1] + b[1], a[2] + b[2], a[3] + b[3], a[4] + b[4])
end

function color_mt.__sub(a, b)
	return new(a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] - b[4])
end

function color_mt.__mul(a, b)
	if type(a) == "number" then
		return new(a * b[1], a * b[2], a * b[3], a * b[4])
	elseif type(b) == "number" then
		return new(b * a[1], b * a[2], b * a[3], b * a[4])
	else
		return new(a[1] * b[1], a[2] * b[2], a[3] * b[3], a[4] * b[4])
	end
end

return setmetatable({}, color_mt)
