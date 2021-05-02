--[[

RBXMX miniMapper V.0.9.0

This code belongs in a ModuleScript with two children:
-A folder class named Filter (currently functional)
-A part named Area which can be moved and resized, but never rotated. The orientation must be Vector3.new(0,0,0)

Simple tutorial.

IMPORTANT: The filter folder is not currently functional. The map will pick up any object, visible or invisble and display its
color on the map.

IMPORTANT: Make sure the Area block is not rotated at all. The orientation must equal Vector3.new(0,0,0)

Step 1:

While Area is still a child of this script, resize and move, but do not rotate, the part to occupy the region you would like mapped.
You may want to make sure that Collisions are turned off in the Home and Model tabs.

Step 2:

Set the X and Y resolution either by using miniMapper.setResolution(x, y) or by changing the
	values directly at the top of the script.
	
This resolution is the amount of data points evenly spread across the region Area occupies.
	When converting this to a .png image you will be given a chance to make the whole image
	larger, but that will not increase detail.
	
To calculate how many data points will be taken you can multiply miniMapper.resolutionX by
	miniMapper.resolutionY.

Step 3:

Call one of the three functions to retrieve a folder filled with data that you must save.

miniMapper.exportMap(applyHeightmap, heightRange)
- Exports a folder that contains the map color information to be read by the python script.
- applyHeightmap is a boolean that controls whether or not a standard heightmap would be added
	to the map color data
- heightRange is a value between 0 and 1 that controls how much the V in HSV can change when
	manipulating colors based on height.


miniMapper.exportHeightMap()
- Exports a folder that contains the map height information to be read by the python script to make a heightmap only image.


miniMapper.exportAll(heightRange)
- Exports three folders. One that acts as if it is miniMapper.exportMap(). One that acts as if it is
	miniMapper.exportMap(true, heightRange). One that acts as if it is miniMapper.exportHeightMap()
- heightRange is a value between 0 and 1 that controls how much the V in HSV can change when manipulating
	colors based on height.

Step 4:

Right click the folder created by the script and click Save to File...

Choose a filename, however do not contain any spaces and save it as a .rbxmx (you will have to
	choose .rbxmx from the dropdown because the default is .rbxm)
	
Step 5:

Open the newly saved file with the python script and follow the on screen prompts.
]]

local miniMapper = {}

miniMapper.resolutionX = 50
miniMapper.resolutionY = 50
miniMapper.filterTable = {}
miniMapper.filterType = Enum.RaycastFilterType.Blacklist
miniMapper.ignoreWaterBool = false
miniMapper.mapData = {}
miniMapper.heightMapData = {}

--Makes sure Area and Filter are children of the script.
function checkEssentials()
	if script:FindFirstChild("Filter") == nil then
		error("A folder named \"Filter\" must be a child of this script.")
	end

	if script:FindFirstChild("Area") == nil then
		error("A part named \"Area\" must be a child of this script.")
	end
end

--Allows the changing of the detail resolution. The higher the numbers, the higher the amount of data points, however it could give a chance of crashing.
function miniMapper.setResolution(x, y)
	if x == nil then
		warn('setResolution(x,y) requires integer parameters that are greater than 1')
	else
		miniMapper.resolutionX = x
		if y == nil then
			warn('setResolution(x,y) requires integer parameters that are greater than 1')
			miniMapper.resolutionY = x
		else
			miniMapper.resolutionY = y
		end
	end
end

--Mapping function. Uses raycasting to collect information about heights and color of specific points on the map.
function miniMapper.Map()
	checkEssentials()
	
	if miniMapper.resolutionX == 0 or miniMapper.resolutionY == 0 then
		error("Resolution must be larger than 0")
	end
	if script.Area.Orientation ~= Vector3.new(0,0,0) then
		script.Area.Orientation = Vector3.new(0,0,0)
		error("script.Area.Orientation must be 0,0,0. The area has been rotated. Please run the function again.")
	end

	local halfSize = Vector3.new(script.Area.Size.X/2, script.Area.Size.Y/2, script.Area.Size.Z/2)
	local min = script.Area.Position - halfSize
	local max = script.Area.Position + halfSize

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = miniMapper.filterType
	--[[
	If anyone can figure out this part, that would be lovely. It does not seem to be blacklisting script.Filter's descendants.
	Even though miniMapper.filterType = Enum.RaycastFilterType.Blacklist.
	
	miniMapper.addFilter(script.Filter)
	miniMapper.addFilter(script.Area)
	raycastParams.FilterDescendantsInstances = miniMapper.filterTable
	]]
	raycastParams.IgnoreWater = miniMapper.ignoreWaterBool

	miniMapper.mapData = {}

	for i=1, miniMapper.resolutionY do
		miniMapper.mapData[i] = {}
		for j=1, miniMapper.resolutionX do

			local origin = Vector3.new(
				min.X + (max.X-min.X)/miniMapper.resolutionX * j,
				max.Y,
				min.Z + (max.Z-min.Z)/miniMapper.resolutionY * i
			)
			local raycastResult = workspace:Raycast(origin, Vector3.new(0,-1,0) * (max.Y-min.Y), raycastParams)

			if raycastResult then

				local success, message = pcall(function ()
					local hitPart = raycastResult.Instance
					local color = nil
					local height = nil
					if hitPart:IsA("Terrain") then

						if raycastResult.Material ~= Enum.Material.Water then
							local matSplit = string.split(tostring(raycastResult.Material), ".")
							if workspace:FindFirstChild("Terrain") == nil then
								warn("No workspace.Terrain all terrain values are nulled")
							else
								color = workspace.Terrain:GetMaterialColor(matSplit[#matSplit])
							end
						else
							color = Color3.fromRGB(170,255,255)
						end


					elseif hitPart:IsA("BasePart") then
						color = hitPart.Color
					else
						print(typeof(hitPart))
					end

					height = raycastResult.Position.Y
					if miniMapper.lowestPoint == nil or miniMapper.lowestPoint > height then
						miniMapper.lowestPoint = height
					end
					if miniMapper.highestPoint == nil or miniMapper.highestPoint < height then
						miniMapper.highestPoint = height
					end

					miniMapper.mapData[i][j] = math.floor(color.R * 255).."/"..math.floor(color.G * 255).."/"..math.floor(color.B * 255).."/"..height
				end)
				if success == false then
					print(message)
					miniMapper.mapData[i][j] = "N"
				end
			else
				miniMapper.mapData[i][j] = "N"
			end

		end
	end
end

--Currently not functional as it seems the raycast filter has not been working and is now commented out.
function miniMapper.changeFilterType(filterType)
	checkEssentials()
	if typeof(filterType) == "string" then
		if string.lower(filterType) == "blacklist" or string.lower(filterType) == "black list" or string.lower(filterType) == "blocklist" or string.lower(filterType) == "block list" then
			miniMapper.filterType = Enum.RaycastFilterType.Blacklist
		elseif string.lower(filterType) == "whitelist" or string.lower(filterType) == "white list" or string.lower(filterType) == "allowlist" or string.lower(filterType) == "allow list" then
			miniMapper.filterType = Enum.RaycastFilterType.Whitelist
		end
	elseif filterType == Enum.RaycastFilterType.Blacklist then
		miniMapper.filterType = Enum.RaycastFilterType.Blacklist
	elseif filterType == Enum.RaycastFilterType.Whitelist then
		miniMapper.filterType = Enum.RaycastFilterType.Whitelist
	else
		warn("Please use a string or an Enum.RaycastFilterType as the parameter")
	end
end

function miniMapper.ignoreWater(value)
	if value == true or value == false then
		miniMapper.ignoreWaterBool = value
	else
		warn("Please use a boolean as the parameter")
	end
end

--Currently not functional as it seems the raycast filter has not been working and is now commented out.
function miniMapper.addFilter(addition)
	checkEssentials()
	if addition then
		table.insert(miniMapper.filterTable, #miniMapper.filterTable+1, addition)
		for _,v in pairs(addition:GetDescendants()) do
			table.insert(miniMapper.filterTable, #miniMapper.filterTable+1, v)
		end
	else
		warn("Please add a parameter")
	end

end

--Currently not functional as it seems the raycast filter has not been working and is now commented out.
function miniMapper.removeFilter(removal)
	checkEssentials()
	if removal then
		local remove = table.find(miniMapper.filterTable, removal)
		if remove then
			table.remove(miniMapper.filterTable, remove)
		else
			warn("")
		end
	else
		warn("Please add a parameter")
	end
	table.insert(miniMapper.filterTable, #miniMapper.filterTable, removal)
end

--Currently not functional as it seems the raycast filter has not been working and is now commented out.
function miniMapper.clearFilter()
	checkEssentials()
	miniMapper.filterTable = {}
end

--Return map data
function miniMapper.getMap()
	if typeof(miniMapper.mapData == "table") and (miniMapper.mapData == {} or #miniMapper.mapData == 0) then
		miniMapper.Map()
	end
	return miniMapper.mapData
end

--Export map data to folder in explorer. If applyHeightmap is true then it will automatically apply the heightmap to the data.
--heightRange should be a value between 0 and 1, which defaults to zero. heightRange is used to apply adjustments to the v in HSV
--depending on the height of the surface in relation to the height of other surfaces.
function miniMapper.exportMap(applyHeightmap, heightRange)
	local map = miniMapper.getMap()
	local mapFolder = Instance.new("Folder")
	if applyHeightmap then
		mapFolder.Name = "MapData + HeightMap - "
	else
		mapFolder.Name = "MapData - "
	end
	mapFolder.Name = mapFolder.Name .. "Export this folder as a .rbxmx file with no spaces in name."
	local buffer = ""
	local bufferCount = 0
	local res = Instance.new("StringValue")
	res.Value = miniMapper.resolutionX..","..miniMapper.resolutionY
	res.Name = "-"
	res.Parent = mapFolder
	
	for a,x in pairs(map) do
		for b, y in pairs(x) do
			if y ~= "N" then
				local split = string.split(y,"/")
				
				if applyHeightmap then
					
					if heightRange == nil then
						heightRange = .6
					end
					
					local h,s,v = Color3.toHSV(Color3.fromRGB(split[1],split[2],split[3]))
					local range = miniMapper.highestPoint - miniMapper.lowestPoint
					local currentPoint = split[4] - miniMapper.lowestPoint
					local newV = math.clamp(v-(.5*heightRange)+(heightRange*(currentPoint/range)), 0, 1)
					local color = Color3.fromHSV(h,s,newV)
					split[1] = math.floor(color.R * 255)
					split[2] = math.floor(color.G * 255)
					split[3] = math.floor(color.B * 255)
				end
				
				buffer = buffer .. split[1] .. "/" .. split[2] .. "/" .. split[3] .. ","
			else
				buffer = buffer .. "N,"
			end
			
			if string.len(buffer) > 195000 then
				local newString = Instance.new("StringValue")
				newString.Value = buffer
				buffer = ""
				newString.Name = bufferCount
				bufferCount += 1
				newString.Parent = mapFolder
			end
			
		end
	end

	if string.len(buffer) > 0 then
		local newString = Instance.new("StringValue")
		newString.Value = buffer
		buffer = ""
		newString.Name = bufferCount
		bufferCount += 1
		newString.Parent = mapFolder
	end
	
	mapFolder.Parent = workspace
end

--Export only HeightMap data. This can be used to create an image of only the heightmap, which can be applied in an editing software
function miniMapper.exportHeightMap()
	local map = miniMapper.getMap()
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "HeightMap - Export this folder as a .rbxmx file with no spaces in name."
	local buffer = ""
	local bufferCount = 0
	local res = Instance.new("StringValue")
	res.Value = miniMapper.resolutionX..","..miniMapper.resolutionY
	res.Name = "-"
	res.Parent = mapFolder
	
	if typeof(miniMapper.heightMapData == "table") and (miniMapper.heightMapData == {} or #miniMapper.heightMapData == 0) then
		for a,x in pairs(map) do
			miniMapper.heightMapData[a] = {}
			for b, y in pairs(x) do
				if y ~= "N" then
					local split = string.split(y,"/")

					local range = miniMapper.highestPoint - miniMapper.lowestPoint
					local currentPoint = split[4] - miniMapper.lowestPoint
					local newV = math.clamp((currentPoint/range), 0, 1)
					split[1] = math.floor(newV * 255 + .5)
					split[2] = math.floor(newV * 255 + .5)
					split[3] = math.floor(newV * 255 + .5)
					
					miniMapper.heightMapData[a][b] = split[1] .. "/" .. split[2] .. "/" .. split[3] .. ","
					buffer = buffer .. miniMapper.heightMapData[a][b]
					
				else
					miniMapper.heightMapData[a][b] = "N,"
					buffer = buffer .. miniMapper.heightMapData[a][b]
				end

				if string.len(buffer) > 195000 then
					local newString = Instance.new("StringValue")
					newString.Value = buffer
					buffer = ""
					newString.Name = bufferCount
					bufferCount += 1
					newString.Parent = mapFolder
				end

			end
		end
	else
		for a,x in pairs(miniMapper.heightMapData) do
			for b,y in pairs(x) do
				buffer = buffer .. y

				if string.len(buffer) > 195000 then
					local newString = Instance.new("StringValue")
					newString.Value = buffer
					buffer = ""
					newString.Name = bufferCount
					bufferCount += 1
					newString.Parent = mapFolder
				end
			end
		end
	end

	if string.len(buffer) > 0 then
		local newString = Instance.new("StringValue")
		newString.Value = buffer
		buffer = ""
		newString.Name = bufferCount
		bufferCount += 1
		newString.Parent = mapFolder
	end

	mapFolder.Parent = workspace
end

--Creates folders for mapdata only, map data + heightmap combined, and heightmap. Each file should be exported as their own .rbxmx file.
function miniMapper.exportAll(heightRange)
	miniMapper.exportMap()
	miniMapper.exportMap(true, heightRange)
	miniMapper.exportHeightMap()
end

return miniMapper