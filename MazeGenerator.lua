local directions = {"up", "right", "down", "left"}
local grid = {}
local continueBuilding = {}

local setMap = game:GetService("ReplicatedStorage").RemoteEvents.setMap

local resettingMap = false

local count = 0

local tileSize = 10
local tileHeight = 20
local newlimit = 25
-- Setup Start
grid["0,0"]  = {}
continueBuilding["0,0"] = {}
for i = 1, #directions do
	grid["0,0"][directions[i]] = true
	continueBuilding["0,0"][directions[i]] = true
end
-- Setup Start

-- This lets the client tell the server to reset the map with the given limit, tileSize, and tileHeight
setMap.OnServerEvent:Connect(function(plr,limit,ts,th)
	if resettingMap then
		return
	end
	tileSize = math.abs(ts)
	tileHeight = math.abs(th)
	newlimit = limit

	resettingMap = true
	wait(2)
	grid = {}
	continueBuilding = {}

	grid["0,0"]  = {}
	continueBuilding["0,0"] = {}
	for i = 1, #directions do
		grid["0,0"][directions[i]] = true
		continueBuilding["0,0"][directions[i]] = true
	end

	for i,v in pairs(game.Workspace:GetChildren()) do
		if v:IsA("Part") then
			if v.Name == "Baseplate" then
				continue
			end
			v:Destroy()
		end
	end
	wait(4)
	print("Settings: Check Limit = " .. limit .. ", Size = " .. ts .. ", Height = " .. th )
	resettingMap = false
	attemptContinue(newlimit)
	generateParts()
	count = 0
end)


-- Force in new direction
function setDirection(gridSpot, direction, open)
	gridSpot[direction] = open
end

function getXandY(str)
	local xy = string.split(str,",")
	local x = tonumber(xy[1])
	local y = tonumber(xy[2])
	
	return x,y
end

function oppositeDirection(direction)
	if direction == "right" then
		return "left"
	elseif direction == "left" then
		return "right"
	elseif direction == "down" then
		return "up"
	elseif direction == "up" then
		return "down"
	end
end

function checkAllTilesAround(gridSpot, str)
	local x,y = getXandY(str)
	
	local options = findClosed(gridSpot)
	for i,v in pairs(options) do
		if i == "right" then
			if checkTileInSpace(gridSpot, str, i) then
				if grid[x+1 .. "," .. y][oppositeDirection(i)] then
					gridSpot[i] = true
				end
			end
		elseif i == "left" then
			if checkTileInSpace(gridSpot, str, i) then
				if grid[x-1 .. "," .. y][oppositeDirection(i)] then
					gridSpot[i] = true
				end
			end
		elseif i == "up" then
			if checkTileInSpace(gridSpot, str, i) then
				if grid[x .. "," .. y+1][oppositeDirection(i)] then
					gridSpot[i] = true
				end
			end
		elseif i == "down" then
			if checkTileInSpace(gridSpot, str, i) then
				if grid[x .. "," .. y-1][oppositeDirection(i)] then
					gridSpot[i] = true
				end
			end
		end
	end
end

function createNewTile(str, direction)
	local x,y = getXandY(str)
	if direction == "up" then
		y += 1
	elseif direction == "right" then
		x += 1
	elseif direction == "left" then
		x -= 1
	elseif direction == "down" then
		y -= 1
	end
	local newStr = "" .. x .. "," .. y
	continueBuilding[newStr] = {}
	grid[newStr] = {}
	return {grid[newStr], newStr}
end

-- Setup random directions on a tile
function giveRandomDirections(gridSpot,str)
	for i = 1, #directions do
		gridSpot[directions[i]] = math.random(1,2) ~= 1 and true or false
	end
	for i,v in pairs(gridSpot) do
		continueBuilding[str][i] = v
	end
end


-- Find options the tile can spread to
function findOptions(gridSpot)
	local options = {}
	for i,v in pairs(gridSpot) do
		if v then
			options[i] = true
		end
	end
	return options
end

function findClosed(gridSpot)
	local options = {}
	for i,v in pairs(gridSpot) do
		if v == false then
			options[i] = true
		end
	end
	return options
end

-- Test if this tile can move farther
function checkContinuePossible(gridSpot,str)
	local x,y = getXandY(str)
	
	for i,v in pairs(gridSpot) do
		if gridSpot["up"] then
			if not grid[x .. "," .. y+1] then
				return true
			end
		end
		if gridSpot["right"] then
			if not grid[x+1 .. "," .. y] then
				return true
			end
		end
		if gridSpot["left"] then
			if not grid[x-1 .. "," .. y] then
				return true
			end
		end
		if gridSpot["down"] then
			if not grid[x .. "," .. y-1] then
				return true
			end
		end
	end
	return false
end

-- Returns true if there is a tile in the space of moving direction
function checkTileInSpace(gridSpot, str, direction)
	local x,y = getXandY(str)
	
	if direction == "up" then
		if grid[x .. "," .. y+1] then
			return true
		end
	elseif direction == "down" then
		if grid[x .. "," .. y-1] then
			return true
		end
	elseif direction == "right" then
		if grid[x+1 .. "," .. y] then
			return true
		end
	elseif direction == "left" then
		if grid[x-1 .. "," .. y] then
			return true
		end
	end
	
	return false
end

function attemptContinue(limit)
	count += 1
	for i,v in pairs(continueBuilding) do
		
		if resettingMap then break end
		--For every tile in this table attempt to add another tile
		if checkContinuePossible(v, i) then
			local options = findOptions(v)
			for a,b in pairs(options) do
				if not checkTileInSpace(v, i, a) then
					local newTile = createNewTile(i, a)
					giveRandomDirections(newTile[1], newTile[2])
					--setDirection(newTile[1], oppositeDirection(a), true)
					checkAllTilesAround(newTile[1],newTile[2])
					continue
				end
			end
		else
			continueBuilding[i] = nil
		end
	end
	
	
	if count < limit then
		attemptContinue(newlimit)
	end
	
	for i,v in pairs(continueBuilding) do
		for a,b in pairs(v) do
			grid[i][a] = false
			continueBuilding[i][a] = false
		end
	end
end


function generateParts()
	local countMade = 0
	for i,v in pairs(grid) do
		local part = Instance.new("Part")
		local x,y = getXandY(i)
		local options = findClosed(v)
		for a,b in pairs(options) do
			if a == "right" then
				part = Instance.new("Part")
				part.Position = Vector3.new(x*tileSize+(tileSize/2-tileSize/8),tileHeight-tileHeight/4,y*tileSize)
				part.Size = Vector3.new(tileSize/4,tileHeight,tileSize)
				part.Anchored = true
				part.Parent = game.Workspace
			elseif a == "left" then
				part = Instance.new("Part")
				part.Position = Vector3.new(x*tileSize-(tileSize/2-tileSize/8),tileHeight-tileHeight/4,y*tileSize)
				part.Size = Vector3.new(tileSize/4,tileHeight,tileSize)
				part.Anchored = true
				part.Parent = game.Workspace
			elseif a == "up" then
				part = Instance.new("Part")
				part.Position = Vector3.new(x*tileSize,tileHeight-tileHeight/4,y*tileSize+(tileSize/2-tileSize/8))
				part.Size = Vector3.new(tileSize,tileHeight,tileSize/4)
				part.Anchored = true
				part.Parent = game.Workspace
			elseif a == "down" then
				part = Instance.new("Part")
				part.Position = Vector3.new(x*tileSize,tileHeight-tileHeight/4,y*tileSize-(tileSize/2-tileSize/8))
				part.Size = Vector3.new(tileSize,tileHeight,tileSize/4)
				part.Anchored = true
				part.Parent = game.Workspace
			end
		end
		
		part = Instance.new("Part")
		part.Color = Color3.fromRGB(150/math.clamp(math.log(((math.abs(x)+1) * (math.abs(y)+1)),10),1,255),255/math.clamp(math.log(((math.abs(x)+1) * (math.abs(y)+1)),6),1,255),10)
		
		part.Position = Vector3.new(x*tileSize,0,y*tileSize)
		part.Size = Vector3.new(tileSize,tileHeight/2,tileSize)
		part.Anchored = true
		
		part.Parent = game.Workspace
		countMade += 1
		if countMade > 1000 then
			countMade = 0
			wait()
		end
	end
end
