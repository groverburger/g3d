-- https://github.com/Nition/UnityOctree
-- https://github.com/Nition/UnityOctree/blob/master/LICENCE
-- https://github.com/Nition/UnityOctree/blob/master/Scripts/BoundsOctree.cs
-- https://github.com/Nition/UnityOctree/blob/master/Scripts/BoundsOctreeNode.cs

--- Octree
-- @module octree

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local intersect  = require(modules .. "intersect")
local mat4       = require(modules .. "mat4")
local utils      = require(modules .. "utils")
local vec3       = require(modules .. "vec3")
local Octree     = {}
local OctreeNode = {}
local Node

Octree.__index     = Octree
OctreeNode.__index = OctreeNode

--== Octree ==--

--- Constructor for the bounds octree.
-- @param initialWorldSize Size of the sides of the initial node, in metres. The octree will never shrink smaller than this
-- @param initialWorldPos Position of the centre of the initial node
-- @param minNodeSize Nodes will stop splitting if the new nodes would be smaller than this (metres)
-- @param looseness Clamped between 1 and 2. Values > 1 let nodes overlap
local function new(initialWorldSize, initialWorldPos, minNodeSize, looseness)
	local tree = setmetatable({}, Octree)

	if minNodeSize > initialWorldSize then
		print("Minimum node size must be at least as big as the initial world size. Was: " .. minNodeSize .. " Adjusted to: " .. initialWorldSize)
		minNodeSize = initialWorldSize
	end

	-- The total amount of objects currently in the tree
	tree.count = 0

	-- Size that the octree was on creation
	tree.initialSize = initialWorldSize

	-- Minimum side length that a node can be - essentially an alternative to having a max depth
	tree.minSize = minNodeSize

	-- Should be a value between 1 and 2. A multiplier for the base size of a node.
	-- 1.0 is a "normal" octree, while values > 1 have overlap
	tree.looseness = utils.clamp(looseness, 1, 2)

	-- Root node of the octree
	tree.rootNode = Node(tree.initialSize, tree.minSize, tree.looseness, initialWorldPos)

	return tree
end

--- Used when growing the octree. Works out where the old root node would fit inside a new, larger root node.
-- @param xDir X direction of growth. 1 or -1
-- @param yDir Y direction of growth. 1 or -1
-- @param zDir Z direction of growth. 1 or -1
-- @return Octant where the root node should be
local function get_root_pos_index(xDir, yDir, zDir)
	local result = xDir > 0 and 1 or 0
	if yDir < 0 then return result + 4 end
	if zDir > 0 then return result + 2 end
end

--- Add an object.
-- @param obj Object to add
-- @param objBounds 3D bounding box around the object
function Octree:add(obj, objBounds)
	-- Add object or expand the octree until it can be added
	local count = 0 -- Safety check against infinite/excessive growth

	while not self.rootNode:add(obj, objBounds) do
		count = count + 1
		self:grow(objBounds.center - self.rootNode.center)

		if count > 20 then
			print("Aborted Add operation as it seemed to be going on forever (" .. count - 1 .. ") attempts at growing the octree.")
			return
		end

		self.count = self.count + 1
	end
end

--- Remove an object. Makes the assumption that the object only exists once in the tree.
-- @param obj Object to remove
-- @return bool True if the object was removed successfully
function Octree:remove(obj)
	local removed = self.rootNode:remove(obj)

	-- See if we can shrink the octree down now that we've removed the item
	if removed then
		self.count = self.count - 1
		self:shrink()
	end

	return removed
end

--- Check if the specified bounds intersect with anything in the tree. See also: get_colliding.
-- @param checkBounds bounds to check
-- @return bool True if there was a collision
function Octree:is_colliding(checkBounds)
	return self.rootNode:is_colliding(checkBounds)
end

--- Returns an array of objects that intersect with the specified bounds, if any. Otherwise returns an empty array. See also: is_colliding.
-- @param checkBounds bounds to check
-- @return table Objects that intersect with the specified bounds
function Octree:get_colliding(checkBounds)
	return self.rootNode:get_colliding(checkBounds)
end

--- Cast a ray through the node and its children
-- @param ray Ray with a position and a direction
-- @param func Function to execute on any objects within child nodes
-- @param out Table to store results of func in
-- @return boolean True if an intersect detected
function Octree:cast_ray(ray, func, out)
	assert(func)
	return self.rootNode:cast_ray(ray, func, out)
end

--- Draws node boundaries visually for debugging.
function Octree:draw_bounds(cube)
	self.rootNode:draw_bounds(cube)
end

--- Draws the bounds of all objects in the tree visually for debugging.
function Octree:draw_objects(cube, filter)
	self.rootNode:draw_objects(cube, filter)
end

--- Grow the octree to fit in all objects.
-- @param direction Direction to grow
function Octree:grow(direction)
	local xDirection = direction.x >= 0 and 1 or -1
	local yDirection = direction.y >= 0 and 1 or -1
	local zDirection = direction.z >= 0 and 1 or -1

	local oldRoot   = self.rootNode
	local half      = self.rootNode.baseLength / 2
	local newLength = self.rootNode.baseLength * 2
	local newCenter = self.rootNode.center + vec3(xDirection * half, yDirection * half, zDirection * half)

	-- Create a new, bigger octree root node
	self.rootNode = Node(newLength, self.minSize, self.looseness, newCenter)

	-- Create 7 new octree children to go with the old root as children of the new root
	local rootPos  = get_root_pos_index(xDirection, yDirection, zDirection)
	local children = {}

	for i = 0, 7 do
		if i == rootPos then
			children[i+1] = oldRoot
		else
			xDirection  = i % 2 == 0 and -1 or 1
			yDirection  = i > 3 and -1 or 1
			zDirection  = (i < 2 or (i > 3 and i < 6)) and -1 or 1
			children[i+1] = Node(self.rootNode.baseLength, self.minSize, self.looseness, newCenter + vec3(xDirection * half, yDirection * half, zDirection * half))
		end
	end

	-- Attach the new children to the new root node
	self.rootNode:set_children(children)
end

--- Shrink the octree if possible, else leave it the same.
function Octree:shrink()
	self.rootNode = self.rootNode:shrink_if_possible(self.initialSize)
end

--== Octree Node ==--

--- Constructor.
-- @param baseLength Length of this node, not taking looseness into account
-- @param minSize Minimum size of nodes in this octree
-- @param looseness Multiplier for baseLengthVal to get the actual size
-- @param center Centre position of this node
local function new_node(baseLength, minSize, looseness, center)
	local node = setmetatable({}, OctreeNode)

	-- Objects in this node
	node.objects = {}

	-- Child nodes
	node.children = {}

	-- If there are already numObjectsAllowed in a node, we split it into children
	-- A generally good number seems to be something around 8-15
	node.numObjectsAllowed = 8

	node:set_values(baseLength, minSize, looseness, center)

	return node
end

local function new_bound(center, size)
	return {
		center = center,
		size   = size,
		min    = center - (size / 2),
		max    = center + (size / 2)
	}
end

--- Add an object.
-- @param obj Object to add
-- @param objBounds 3D bounding box around the object
-- @return boolean True if the object fits entirely within this node
function OctreeNode:add(obj, objBounds)
	if not intersect.encapsulate_aabb(self.bounds, objBounds) then
		return false
	end

	-- We know it fits at this level if we've got this far
	-- Just add if few objects are here, or children would be below min size
	if #self.objects < self.numObjectsAllowed
	or self.baseLength / 2 < self.minSize then
		table.insert(self.objects, {
			data   = obj,
			bounds = objBounds
		})
	else
		-- Fits at this level, but we can go deeper. Would it fit there?

		local best_fit_child

		-- Create the 8 children
		if #self.children == 0 then
			self:split()

			if #self.children == 0 then
				print("Child creation failed for an unknown reason. Early exit.")
				return false
			end

			-- Now that we have the new children, see if this node's existing objects would fit there
			for i = #self.objects, 1, -1 do
				local object = self.objects[i]
				-- Find which child the object is closest to based on where the
				-- object's center is located in relation to the octree's center.
				best_fit_child = self:best_fit_child(object.bounds)

				-- Does it fit?
				if intersect.encapsulate_aabb(self.children[best_fit_child].bounds, object.bounds) then
					self.children[best_fit_child]:add(object.data, object.bounds) -- Go a level deeper
					table.remove(self.objects, i) -- Remove from here
				end
			end
		end

		-- Now handle the new object we're adding now
		best_fit_child = self:best_fit_child(objBounds)

		if intersect.encapsulate_aabb(self.children[best_fit_child].bounds, objBounds) then
			self.children[best_fit_child]:add(obj, objBounds)
		else
			table.insert(self.objects, {
				data   = obj,
				bounds = objBounds
			})
		end
	end

	return true
end

--- Remove an object. Makes the assumption that the object only exists once in the tree.
-- @param obj Object to remove
-- @return boolean True if the object was removed successfully
function OctreeNode:remove(obj)
	local removed = false

	for i, object in ipairs(self.objects) do
		if object == obj then
			removed = table.remove(self.objects, i) and true or false
			break
		end
	end

	if not removed then
		for _, child in ipairs(self.children) do
			removed = child:remove(obj)
			if removed then break end
		end
	end

	if removed then
		-- Check if we should merge nodes now that we've removed an item
		if self:should_merge() then
			self:merge()
		end
	end

	return removed
end

--- Check if the specified bounds intersect with anything in the tree. See also: get_colliding.
-- @param checkBounds Bounds to check
-- @return boolean True if there was a collision
function OctreeNode:is_colliding(checkBounds)
	-- Are the input bounds at least partially in this node?
	if not intersect.aabb_aabb(self.bounds, checkBounds) then
		return false
	end

	-- Check against any objects in this node
	for _, object in ipairs(self.objects) do
		if intersect.aabb_aabb(object.bounds, checkBounds) then
			return true
		end
	end

	-- Check children
	for _, child in ipairs(self.children) do
		if child:is_colliding(checkBounds) then
			return true
		end
	end

	return false
end

--- Returns an array of objects that intersect with the specified bounds, if any. Otherwise returns an empty array. See also: is_colliding.
-- @param checkBounds Bounds to check. Passing by ref as it improve performance with structs
-- @param results List results
-- @return table Objects that intersect with the specified bounds
function OctreeNode:get_colliding(checkBounds, results)
	results = results or {}

	-- Are the input bounds at least partially in this node?
	if not intersect.aabb_aabb(self.bounds, checkBounds) then
		return results
	end

	-- Check against any objects in this node
	for _, object in ipairs(self.objects) do
		if intersect.aabb_aabb(object.bounds, checkBounds) then
			table.insert(results, object.data)
		end
	end

	-- Check children
	for _, child in ipairs(self.children) do
		results = child:get_colliding(checkBounds, results)
	end

	return results
end

--- Cast a ray through the node and its children
-- @param ray Ray with a position and a direction
-- @param func Function to execute on any objects within child nodes
-- @param out Table to store results of func in
-- @param depth (used internally)
-- @return boolean True if an intersect is detected
function OctreeNode:cast_ray(ray, func, out, depth)
	depth = depth or 1

	if intersect.ray_aabb(ray, self.bounds) then
		if #self.objects > 0 then
			local hit = func(ray, self.objects, out)

			if hit then
				return hit
			end
		end

		for _, child in ipairs(self.children) do
			local hit = child:cast_ray(ray, func, out, depth + 1)

			if hit then
				return hit
			end
		end
	end

	return false
end

--- Set the 8 children of this octree.
-- @param childOctrees The 8 new child nodes
function OctreeNode:set_children(childOctrees)
	if #childOctrees ~= 8 then
		print("Child octree array must be length 8. Was length: " .. #childOctrees)
		return
	end

	self.children = childOctrees
end

--- We can shrink the octree if:
--- - This node is >= double minLength in length
--- - All objects in the root node are within one octant
--- - This node doesn't have children, or does but 7/8 children are empty
--- We can also shrink it if there are no objects left at all!
-- @param minLength Minimum dimensions of a node in this octree
-- @return table The new root, or the existing one if we didn't shrink
function OctreeNode:shrink_if_possible(minLength)
	if self.baseLength < 2 * minLength then
		return self
	end

	if #self.objects == 0 and #self.children == 0 then
		return self
	end

	-- Check objects in root
	local bestFit = 0

	for i, object in ipairs(self.objects) do
		local newBestFit = self:best_fit_child(object.bounds)

		if i == 1 or newBestFit == bestFit then
			-- In same octant as the other(s). Does it fit completely inside that octant?
			if intersect.encapsulate_aabb(self.childBounds[newBestFit], object.bounds) then
				if bestFit < 1 then
					bestFit = newBestFit
				end
			else
				-- Nope, so we can't reduce. Otherwise we continue
				return self
			end
		else
			return self -- Can't reduce - objects fit in different octants
		end
	end

	-- Check objects in children if there are any
	if #self.children > 0 then
		local childHadContent = false

		for i, child in ipairs(self.children) do
			if child:has_any_objects() then
				if childHadContent then
					return self -- Can't shrink - another child had content already
				end

				if bestFit > 0 and bestFit ~= i then
					return self -- Can't reduce - objects in root are in a different octant to objects in child
				end

				childHadContent = true
				bestFit = i
			end
		end
	end

	-- Can reduce
	if #self.children == 0 then
		-- We don't have any children, so just shrink this node to the new size
		-- We already know that everything will still fit in it
		self:set_values(self.baseLength / 2, self.minSize, self.looseness, self.childBounds[bestFit].center)
		return self
	end

	-- We have children. Use the appropriate child as the new root node
	return self.children[bestFit]
end

--- Set values for this node.
-- @param baseLength Length of this node, not taking looseness into account
-- @param minSize Minimum size of nodes in this octree
-- @param looseness Multiplier for baseLengthVal to get the actual size
-- @param center Centre position of this node
function OctreeNode:set_values(baseLength, minSize, looseness, center)
	-- Length of this node if it has a looseness of 1.0
	self.baseLength = baseLength

	-- Minimum size for a node in this octree
	self.minSize = minSize

	-- Looseness value for this node
	self.looseness = looseness

	-- Centre of this node
	self.center = center

	-- Actual length of sides, taking the looseness value into account
	self.adjLength = self.looseness * self.baseLength

	-- Create the bounding box.
	self.size = vec3(self.adjLength, self.adjLength, self.adjLength)

	-- Bounding box that represents this node
	self.bounds = new_bound(self.center, self.size)

	self.quarter           = self.baseLength / 4
	self.childActualLength = (self.baseLength / 2) * self.looseness
	self.childActualSize   = vec3(self.childActualLength, self.childActualLength, self.childActualLength)

	-- Bounds of potential children to this node. These are actual size (with looseness taken into account), not base size
	self.childBounds =  {
		new_bound(self.center + vec3(-self.quarter,  self.quarter, -self.quarter), self.childActualSize),
		new_bound(self.center + vec3( self.quarter,  self.quarter, -self.quarter), self.childActualSize),
		new_bound(self.center + vec3(-self.quarter,  self.quarter,  self.quarter), self.childActualSize),
		new_bound(self.center + vec3( self.quarter,  self.quarter,  self.quarter), self.childActualSize),
		new_bound(self.center + vec3(-self.quarter, -self.quarter, -self.quarter), self.childActualSize),
		new_bound(self.center + vec3( self.quarter, -self.quarter, -self.quarter), self.childActualSize),
		new_bound(self.center + vec3(-self.quarter, -self.quarter,  self.quarter), self.childActualSize),
		new_bound(self.center + vec3( self.quarter, -self.quarter,  self.quarter), self.childActualSize)
	}
end

--- Splits the octree into eight children.
function OctreeNode:split()
	if #self.children > 0 then return end

	local quarter   = self.baseLength / 4
	local newLength = self.baseLength / 2

	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3(-quarter,  quarter, -quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3( quarter,  quarter, -quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3(-quarter,  quarter,  quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3( quarter,  quarter,  quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3(-quarter, -quarter, -quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3( quarter, -quarter, -quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3(-quarter, -quarter,  quarter)))
	table.insert(self.children, Node(newLength, self.minSize, self.looseness, self.center + vec3( quarter, -quarter,  quarter)))
end

--- Merge all children into this node - the opposite of Split.
--- Note: We only have to check one level down since a merge will never happen if the children already have children,
--- since THAT won't happen unless there are already too many objects to merge.
function OctreeNode:merge()
	for _, child in ipairs(self.children) do
		for _, object in ipairs(child.objects) do
			table.insert(self.objects, object)
		end
	end

	-- Remove the child nodes (and the objects in them - they've been added elsewhere now)
	self.children = {}
end

--- Find which child node this object would be most likely to fit in.
-- @param objBounds The object's bounds
-- @return number One of the eight child octants
function OctreeNode:best_fit_child(objBounds)
	return (objBounds.center.x <= self.center.x and 0 or 1) + (objBounds.center.y >= self.center.y and 0 or 4) + (objBounds.center.z <= self.center.z and 0 or 2) + 1
end

--- Checks if there are few enough objects in this node and its children that the children should all be merged into this.
-- @return boolean True there are less or the same abount of objects in this and its children than numObjectsAllowed
function OctreeNode:should_merge()
	local totalObjects = #self.objects

	for _, child in ipairs(self.children) do
		if #child.children > 0 then
			-- If any of the *children* have children, there are definitely too many to merge,
			-- or the child would have been merged already
			return false
		end

		totalObjects = totalObjects + #child.objects
	end

	return totalObjects <= self.numObjectsAllowed
end

--- Checks if this node or anything below it has something in it.
-- @return boolean True if this node or any of its children, grandchildren etc have something in the
function OctreeNode:has_any_objects()
	if #self.objects > 0 then return true end

	for _, child in ipairs(self.children) do
		if child:has_any_objects() then return true end
	end

	return false
end

--- Draws node boundaries visually for debugging.
-- @param cube Cube model to draw
-- @param depth Used for recurcive calls to this method
function OctreeNode:draw_bounds(cube, depth)
	depth = depth or 0
	local tint = depth / 7 -- Will eventually get values > 1. Color rounds to 1 automatically

	love.graphics.setColor(tint * 255, 0, (1 - tint) * 255)
	local m = mat4()
		:translate(self.center)
		:scale(vec3(self.adjLength, self.adjLength, self.adjLength))

	love.graphics.updateMatrix("transform", m)
	love.graphics.setWireframe(true)
	love.graphics.draw(cube)
	love.graphics.setWireframe(false)

	for _, child in ipairs(self.children) do
		child:draw_bounds(cube, depth + 1)
	end

	love.graphics.setColor(255, 255, 255)
end

--- Draws the bounds of all objects in the tree visually for debugging.
-- @param cube Cube model to draw
-- @param filter a function returning true or false to determine visibility.
function OctreeNode:draw_objects(cube, filter)
	local tint = self.baseLength / 20
	love.graphics.setColor(0, (1 - tint) * 255, tint * 255, 63)

	for _, object in ipairs(self.objects) do
		if filter and filter(object.data) or not filter then
			local m = mat4()
				:translate(object.bounds.center)
				:scale(object.bounds.size)

			love.graphics.updateMatrix("transform", m)
			love.graphics.draw(cube)
		end
	end

	for _, child in ipairs(self.children) do
		child:draw_objects(cube, filter)
	end

	love.graphics.setColor(255, 255, 255)
end

Node = setmetatable({
	new = new_node
}, {
	__call = function(_, ...) return new_node(...) end
})

return setmetatable({
	new = new
}, {
	__call = function(_, ...) return new(...) end
})
