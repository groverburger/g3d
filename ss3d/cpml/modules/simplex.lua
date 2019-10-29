--- Simplex Noise
-- @module simplex

--
-- Based on code in "Simplex noise demystified", by Stefan Gustavson
-- www.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
--
-- Thanks to Mike Pall for some cleanup and improvements (and for LuaJIT!)
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

if _G.love and _G.love.math then
	return love.math.noise
end

-- Bail out with dummy module if FFI is missing.
local has_ffi, ffi = pcall(require, "ffi")
if not has_ffi then
	return function()
		return 0
	end
end

-- Modules --
local bit = require("bit")

-- Imports --
local band   = bit.band
local bor    = bit.bor
local floor  = math.floor
local lshift = bit.lshift
local max    = math.max
local rshift = bit.rshift

-- Permutation of 0-255, replicated to allow easy indexing with sums of two bytes --
local Perms = ffi.new("uint8_t[512]", {
	151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
	140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
	247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
	 57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
	 74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
	 60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
	 65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
	200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
	 52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
	207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
	119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
	129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
	218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
	 81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
	184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
	222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180
})

-- The above, mod 12 for each element --
local Perms12 = ffi.new("uint8_t[512]")

for i = 0, 255 do
	local x = Perms[i] % 12

	Perms[i + 256], Perms12[i], Perms12[i + 256] = Perms[i], x, x
end

-- Gradients for 2D, 3D case --
local Grads3 = ffi.new("const double[12][3]",
	{ 1, 1, 0 }, { -1, 1, 0 }, { 1, -1, 0 }, { -1, -1, 0 },
	{ 1, 0, 1 }, { -1, 0, 1 }, { 1, 0, -1 }, { -1, 0, -1 },
	{ 0, 1, 1 }, { 0, -1, 1 }, { 0, 1, -1 }, { 0, -1, -1 }
)

-- 2D weight contribution
local function GetN2(bx, by, x, y)
	local t = .5 - x * x - y * y
	local index = Perms12[bx + Perms[by]]

	return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y)
end

local function simplex_2d(x, y)
	--[[
		2D skew factors:
		F = (math.sqrt(3) - 1) / 2
		G = (3 - math.sqrt(3)) / 6
		G2 = 2 * G - 1
	]]

	-- Skew the input space to determine which simplex cell we are in.
	local s = (x + y) * 0.366025403 -- F
	local ix, iy = floor(x + s), floor(y + s)

	-- Unskew the cell origin back to (x, y) space.
	local t = (ix + iy) * 0.211324865 -- G
	local x0 = x + t - ix
	local y0 = y + t - iy

	-- Calculate the contribution from the two fixed corners.
	-- A step of (1,0) in (i,j) means a step of (1-G,-G) in (x,y), and
	-- A step of (0,1) in (i,j) means a step of (-G,1-G) in (x,y).
	ix, iy = band(ix, 255), band(iy, 255)

	local n0 = GetN2(ix, iy, x0, y0)
	local n2 = GetN2(ix + 1, iy + 1, x0 - 0.577350270, y0 - 0.577350270) -- G2

	--[[
		Determine other corner based on simplex (equilateral triangle) we are in:
		if x0 > y0 then
			ix, x1 = ix + 1, x1 - 1
		else
			iy, y1 = iy + 1, y1 - 1
		end
	]]
	local xi = rshift(floor(y0 - x0), 31) -- y0 < x0
	local n1 = GetN2(ix + xi, iy + (1 - xi), x0 + 0.211324865 - xi, y0 - 0.788675135 + xi) -- x0 + G - xi, y0 + G - (1 - xi)

	-- Add contributions from each corner to get the final noise value.
	-- The result is scaled to return values in the interval [-1,1].
	return 70.1480580019 * (n0 + n1 + n2)
end

-- 3D weight contribution
local function GetN3(ix, iy, iz, x, y, z)
	local t = .6 - x * x - y * y - z * z
	local index = Perms12[ix + Perms[iy + Perms[iz]]]

	return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y + Grads3[index][2] * z)
end

local function simplex_3d(x, y, z)
	--[[
		3D skew factors:
		F = 1 / 3
		G = 1 / 6
		G2 = 2 * G
		G3 = 3 * G - 1
	]]

	-- Skew the input space to determine which simplex cell we are in.
	local s = (x + y + z) * 0.333333333 -- F
	local ix, iy, iz = floor(x + s), floor(y + s), floor(z + s)

	-- Unskew the cell origin back to (x, y, z) space.
	local t = (ix + iy + iz) * 0.166666667 -- G
	local x0 = x + t - ix
	local y0 = y + t - iy
	local z0 = z + t - iz

	-- Calculate the contribution from the two fixed corners.
	-- A step of (1,0,0) in (i,j,k) means a step of (1-G,-G,-G) in (x,y,z);
	-- a step of (0,1,0) in (i,j,k) means a step of (-G,1-G,-G) in (x,y,z);
	-- a step of (0,0,1) in (i,j,k) means a step of (-G,-G,1-G) in (x,y,z).
	ix, iy, iz = band(ix, 255), band(iy, 255), band(iz, 255)

	local n0 = GetN3(ix, iy, iz, x0, y0, z0)
	local n3 = GetN3(ix + 1, iy + 1, iz + 1, x0 - 0.5, y0 - 0.5, z0 - 0.5) -- G3

	--[[
		Determine other corners based on simplex (skewed tetrahedron) we are in:

		if x0 >= y0 then -- ~A
			if y0 >= z0 then -- ~A and ~B
				i1, j1, k1, i2, j2, k2 = 1, 0, 0, 1, 1, 0
			elseif x0 >= z0 then -- ~A and B and ~C
				i1, j1, k1, i2, j2, k2 = 1, 0, 0, 1, 0, 1
			else -- ~A and B and C
				i1, j1, k1, i2, j2, k2 = 0, 0, 1, 1, 0, 1
			end
		else -- A
			if y0 < z0 then -- A and B
				i1, j1, k1, i2, j2, k2 = 0, 0, 1, 0, 1, 1
			elseif x0 < z0 then -- A and ~B and C
				i1, j1, k1, i2, j2, k2 = 0, 1, 0, 0, 1, 1
			else -- A and ~B and ~C
				i1, j1, k1, i2, j2, k2 = 0, 1, 0, 1, 1, 0
			end
		end
	]]

	local xLy = rshift(floor(x0 - y0), 31) -- x0 < y0
	local yLz = rshift(floor(y0 - z0), 31) -- y0 < z0
	local xLz = rshift(floor(x0 - z0), 31) -- x0 < z0

	local i1 = band(1 - xLy, bor(1 - yLz, 1 - xLz)) -- x0 >= y0 and (y0 >= z0 or x0 >= z0)
	local j1 = band(xLy, 1 - yLz) -- x0 < y0 and y0 >= z0
	local k1 = band(yLz, bor(xLy, xLz)) -- y0 < z0 and (x0 < y0 or x0 < z0)

	local i2 = bor(1 - xLy, band(1 - yLz, 1 - xLz)) -- x0 >= y0 or (y0 >= z0 and x0 >= z0)
	local j2 = bor(xLy, 1 - yLz) -- x0 < y0 or y0 >= z0
	local k2 = bor(band(1 - xLy, yLz), band(xLy, bor(yLz, xLz))) -- (x0 >= y0 and y0 < z0) or (x0 < y0 and (y0 < z0 or x0 < z0))

	local n1 = GetN3(ix + i1, iy + j1, iz + k1, x0 + 0.166666667 - i1, y0 + 0.166666667 - j1, z0 + 0.166666667 - k1) -- G
	local n2 = GetN3(ix + i2, iy + j2, iz + k2, x0 + 0.333333333 - i2, y0 + 0.333333333 - j2, z0 + 0.333333333 - k2) -- G2

	-- Add contributions from each corner to get the final noise value.
	-- The result is scaled to stay just inside [-1,1]
	return 28.452842 * (n0 + n1 + n2 + n3)
end

-- Gradients for 4D case --
local Grads4 = ffi.new("const double[32][4]",
	{ 0, 1, 1, 1 }, { 0, 1, 1, -1 }, { 0, 1, -1, 1 }, { 0, 1, -1, -1 },
	{ 0, -1, 1, 1 }, { 0, -1, 1, -1 }, { 0, -1, -1, 1 }, { 0, -1, -1, -1 },
	{ 1, 0, 1, 1 }, { 1, 0, 1, -1 }, { 1, 0, -1, 1 }, { 1, 0, -1, -1 },
	{ -1, 0, 1, 1 }, { -1, 0, 1, -1 }, { -1, 0, -1, 1 }, { -1, 0, -1, -1 },
	{ 1, 1, 0, 1 }, { 1, 1, 0, -1 }, { 1, -1, 0, 1 }, { 1, -1, 0, -1 },
	{ -1, 1, 0, 1 }, { -1, 1, 0, -1 }, { -1, -1, 0, 1 }, { -1, -1, 0, -1 },
	{ 1, 1, 1, 0 }, { 1, 1, -1, 0 }, { 1, -1, 1, 0 }, { 1, -1, -1, 0 },
	{ -1, 1, 1, 0 }, { -1, 1, -1, 0 }, { -1, -1, 1, 0 }, { -1, -1, -1, 0 }
)

-- 4D weight contribution
local function GetN4(ix, iy, iz, iw, x, y, z, w)
	local t = .6 - x * x - y * y - z * z - w * w
	local index = band(Perms[ix + Perms[iy + Perms[iz + Perms[iw]]]], 0x1F)

	return max(0, (t * t) * (t * t)) * (Grads4[index][0] * x + Grads4[index][1] * y + Grads4[index][2] * z + Grads4[index][3] * w)
end

-- A lookup table to traverse the simplex around a given point in 4D.
-- Details can be found where this table is used, in the 4D noise method.
local Simplex = ffi.new("uint8_t[64][4]",
	{ 0, 1, 2, 3 }, { 0, 1, 3, 2 }, {}, { 0, 2, 3, 1 }, {}, {}, {}, { 1, 2, 3 },
	{ 0, 2, 1, 3 }, {}, { 0, 3, 1, 2 }, { 0, 3, 2, 1 }, {}, {}, {}, { 1, 3, 2 },
	{}, {}, {}, {}, {}, {}, {}, {},
	{ 1, 2, 0, 3 }, {}, { 1, 3, 0, 2 }, {}, {}, {}, { 2, 3, 0, 1 }, { 2, 3, 1 },
	{ 1, 0, 2, 3 }, { 1, 0, 3, 2 }, {}, {}, {}, { 2, 0, 3, 1 }, {}, { 2, 1, 3 },
	{}, {}, {}, {}, {}, {}, {}, {},
	{ 2, 0, 1, 3 }, {}, {}, {}, { 3, 0, 1, 2 }, { 3, 0, 2, 1 }, {}, { 3, 1, 2 },
	{ 2, 1, 0, 3 }, {}, {}, {}, { 3, 1, 0, 2 }, {}, { 3, 2, 0, 1 }, { 3, 2, 1 }
)

-- Convert the above indices to masks that can be shifted / anded into offsets --
for i = 0, 63 do
	Simplex[i][0] = lshift(1, Simplex[i][0]) - 1
	Simplex[i][1] = lshift(1, Simplex[i][1]) - 1
	Simplex[i][2] = lshift(1, Simplex[i][2]) - 1
	Simplex[i][3] = lshift(1, Simplex[i][3]) - 1
end

local function simplex_4d(x, y, z, w)
	--[[
		4D skew factors:
		F = (math.sqrt(5) - 1) / 4
		G = (5 - math.sqrt(5)) / 20
		G2 = 2 * G
		G3 = 3 * G
		G4 = 4 * G - 1
	]]

	-- Skew the input space to determine which simplex cell we are in.
	local s = (x + y + z + w) * 0.309016994 -- F
	local ix, iy, iz, iw = floor(x + s), floor(y + s), floor(z + s), floor(w + s)

	-- Unskew the cell origin back to (x, y, z) space.
	local t = (ix + iy + iz + iw) * 0.138196601 -- G
	local x0 = x + t - ix
	local y0 = y + t - iy
	local z0 = z + t - iz
	local w0 = w + t - iw

	-- For the 4D case, the simplex is a 4D shape I won't even try to describe.
	-- To find out which of the 24 possible simplices we're in, we need to
	-- determine the magnitude ordering of x0, y0, z0 and w0.
	-- The method below is a good way of finding the ordering of x,y,z,w and
	-- then find the correct traversal order for the simplex we�re in.
	-- First, six pair-wise comparisons are performed between each possible pair
	-- of the four coordinates, and the results are used to add up binary bits
	-- for an integer index.
	local c1 = band(rshift(floor(y0 - x0), 26), 32)
	local c2 = band(rshift(floor(z0 - x0), 27), 16)
	local c3 = band(rshift(floor(z0 - y0), 28), 8)
	local c4 = band(rshift(floor(w0 - x0), 29), 4)
	local c5 = band(rshift(floor(w0 - y0), 30), 2)
	local c6 = rshift(floor(w0 - z0), 31)

	-- Simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
	-- Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
	-- impossible. Only the 24 indices which have non-zero entries make any sense.
	-- We use a thresholding to set the coordinates in turn from the largest magnitude.
	local c = c1 + c2 + c3 + c4 + c5 + c6

	-- The number 3 (i.e. bit 2) in the "simplex" array is at the position of the largest coordinate.
	local i1 = rshift(Simplex[c][0], 2)
	local j1 = rshift(Simplex[c][1], 2)
	local k1 = rshift(Simplex[c][2], 2)
	local l1 = rshift(Simplex[c][3], 2)

	-- The number 2 (i.e. bit 1) in the "simplex" array is at the second largest coordinate.
	local i2 = band(rshift(Simplex[c][0], 1), 1)
	local j2 = band(rshift(Simplex[c][1], 1), 1)
	local k2 = band(rshift(Simplex[c][2], 1), 1)
	local l2 = band(rshift(Simplex[c][3], 1), 1)

	-- The number 1 (i.e. bit 0) in the "simplex" array is at the second smallest coordinate.
	local i3 = band(Simplex[c][0], 1)
	local j3 = band(Simplex[c][1], 1)
	local k3 = band(Simplex[c][2], 1)
	local l3 = band(Simplex[c][3], 1)

	-- Work out the hashed gradient indices of the five simplex corners
	-- Sum up and scale the result to cover the range [-1,1]
	ix, iy, iz, iw = band(ix, 255), band(iy, 255), band(iz, 255), band(iw, 255)

	local n0 = GetN4(ix, iy, iz, iw, x0, y0, z0, w0)
	local n1 = GetN4(ix + i1, iy + j1, iz + k1, iw + l1, x0 + 0.138196601 - i1, y0 + 0.138196601 - j1, z0 + 0.138196601 - k1, w0 + 0.138196601 - l1) -- G
	local n2 = GetN4(ix + i2, iy + j2, iz + k2, iw + l2, x0 + 0.276393202 - i2, y0 + 0.276393202 - j2, z0 + 0.276393202 - k2, w0 + 0.276393202 - l2) -- G2
	local n3 = GetN4(ix + i3, iy + j3, iz + k3, iw + l3, x0 + 0.414589803 - i3, y0 + 0.414589803 - j3, z0 + 0.414589803 - k3, w0 + 0.414589803 - l3) -- G3
	local n4 = GetN4(ix + 1, iy + 1, iz + 1, iw + 1, x0 - 0.447213595, y0 - 0.447213595, z0 - 0.447213595, w0 - 0.447213595) -- G4

	return 2.210600293 * (n0 + n1 + n2 + n3 + n4)
end

--- Simplex Noise
-- @param x
-- @param y
-- @param z optional
-- @param w optional
-- @return Noise value in the range [-1, +1]
return function(x, y, z, w)
	if w then
		return simplex_4d(x, y, z, w)
	end
	if z then
		return simplex_3d(x, y, z)
	end
	if y then
		return simplex_2d(x, y)
	end
	error "Simplex requires at least two arguments"
end
