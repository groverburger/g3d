local octree = require "modules.octree"

describe("octree:", function()
end)

--[[
local function new(initialWorldSize, initialWorldPos, minNodeSize, looseness)
function Octree:add(obj, objBounds)
function Octree:remove(obj)
function Octree:is_colliding(checkBounds)
function Octree:get_colliding(checkBounds)
function Octree:cast_ray(ray, func, out)
function Octree:draw_bounds(cube)
function Octree:draw_objects(cube, filter)
function Octree:grow(direction)
function Octree:shrink()
function Octree:get_root_pos_index(xDir, yDir, zDir)

function OctreeNode:add(obj, objBounds)
function OctreeNode:remove(obj)
function OctreeNode:is_colliding(checkBounds)
function OctreeNode:get_colliding(checkBounds, results)
function OctreeNode:cast_ray(ray, func, out, depth)
function OctreeNode:set_children(childOctrees)
function OctreeNode:shrink_if_possible(minLength)
function OctreeNode:set_values(baseLength, minSize, looseness, center)
function OctreeNode:split()
function OctreeNode:merge()
function OctreeNode:best_fit_child(objBounds)
function OctreeNode:should_merge()
function OctreeNode:has_any_objects()
function OctreeNode:draw_bounds(cube, depth)
function OctreeNode:draw_objects(cube, filter)
--]]