-- written by groverbuger for g3d
-- september 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- simple obj loader
----------------------------------------------------------------------------------------------------

-- give path of file
-- returns a lua table representation
return function (path, flipU, flipV)
    local positions, faces, uvs, normals, model = {}, {}, {}, {}, {}

    -- go line by line through the file
    for line in love.filesystem.lines(path) do
        local words = {}

        -- split the line into words
        for word in line:gmatch "([^%s]+)" do
            table.insert(words, word)
        end

        local firstWord = words[1]

        if firstWord == "v" then
            -- if the first word in this line is a "v", then this defines a vertex's position

            table.insert(positions, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "vt" then
            -- if the first word in this line is a "vt", then this defines a texture coordinate
			
			-- Blender 2.9+ V axis points UP, whereas LÖVE's Y axis points DOWN
			-- Not sure if any other software has U axis inverted, but why not add this just in case?
			local U, V = tonumber(words[2]), tonumber(words[3])			
			if flipU then U = 1 - U end
			if flipV then V = 1 - V end
			
            table.insert(uvs, {U,V})
        elseif firstWord == "vn" then
            -- if the first word in this line is a "vn", then this defines a vertex normal

            table.insert(normals, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "f" then
            -- if the first word in this line is a "f", then this is a face
            -- a face takes three point definitions
            -- the arguments a point definition takes are vertex, vertex texture, vertex normal in that order

            assert(#words == 4, ("Faces in %s must be triangulated before they can be used in g3d!"):format(path))
            local face = {v = {}, vt = {}, n = {}}

            for i=2, #words do
                local v, vt, n = words[i]:match "(%d+)/(%d+)/(%d+)"
                table.insert(face.v,  tonumber(v))
                table.insert(face.vt, tonumber(vt))
                table.insert(face.n,  tonumber(n))
            end

            table.insert(faces, face)
        end
    end

    -- put it all together in the right order
    for _, face in pairs(faces) do
        for i=1, 3 do
            local vert = {unpack(positions[face.v[i]])}
            for _, uv in ipairs(uvs[face.vt[i]]) do table.insert(vert, uv) end
            for _, normal in ipairs(normals[face.n[i]]) do table.insert(vert, normal) end
            table.insert(model, vert)
        end
    end

    return model
end
