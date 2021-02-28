tArgs = { ... }

local goTo =  {}
local facing
local blocksv
local blocks

goTo.x = tonumber(tArgs[1])
goTo.y = tonumber(tArgs[2]) or 64
goTo.z = tonumber(tArgs[3])

local function turn(_side,_n)  --- function to turn 
	if _side == "left" then
		for i=1, _n do
			turtle.turnLeft()
		end
	elseif _side == "right" then
		for i=1, _n do
			turtle.turnRight()
		end
	end
end

local function ensureWalking()  --- make sure that the turtle walked
	if turtle.forward() then  --- ensure that the turtle walked
		blocks = blocks - 1
		return true
	else
		turtle.attack()
		ensureWalking()
	end
end

local function ensureVertical(_a) --- call like ensureVertical{direction = "up"}
	if _a == "up" then	
		if turtle.up() then  --- ensure that the turtle walked
			blocksv = blocksv - 1
			return true
		else
			turtle.attackUp()
			ensureVertical(_a)
		end
	elseif _a == "down" then
		if turtle.down() then  --- ensure that the turtle walked
			blocksv = blocksv - 1
			return true
		else
			turtle.attackDown()
			ensureVertical(_a)
		end
	end
end

local function digAndWalk(_a) --- function to dig, walk and replace blocks, call like digAndWalk{times = 1}
	if _a == nil then _a = 1 end
	blocks = _a or 1
	turtle.select(4)
	turtle.dropUp()
	while blocks > 0 do
		while turtle.detect() do
			turtle.dig()
			if turtle.getItemCount(4) < 1 then  --  making sure it is not lava
				break
			end
		end
		ensureWalking()
	end
end

local function getFacing()
	local cx, cy, cz = gps.locate() -- get the current position
	digAndWalk()
	local nx, ny, nz = gps.locate() -- get the new position
	if nx > cx then
		facing = "east"
	elseif nx < cx then
		facing = "west"
	elseif nz > cz then
		facing = "south"
	elseif nz < cz then
		facing = "north"
	end
	print(facing)
end

local function facingNorth()
	if facing == "north" then
		return true
	elseif facing == "east" then
		facing = "north"
		turn("left",1)
		return true
	elseif facing == "south" then
		facing = "north"
		turn("right",2)
		return true
	elseif facing == "west" then
		facing = "north"
		turn("right",1)
		return true
	else 
		return false
	end
end

local function pickItem(_from,_to,_number)  -- function to use enderchest of illing cabinet as storage for fuel, and also pick it
	turtle.select(7)
	turtle.digDown()
	turtle.select(_from)
	turtle.placeDown()
	turtle.select(_to)
	turtle.suckDown(_number)
	turtle.select(_from)
	turtle.digDown()
	turtle.select(7)
	turtle.placeDown()	
end

local function checkFuel()
	local cx, cy, cz = gps.locate() --- yes again!
	local fuelNeeded = math.ceil(math.abs(cx - goTo.x) + math.abs(cz - goTo.z) + math.abs(cy - goTo.y))
	local coalNeeded = math.ceil(fuelNeeded/80 - turtle.getFuelLevel())
	if coalNeeded > 64 then
		print("Put "..tostring(coalNeeded).." coal in the first slot")
		return false
	elseif coalNeeded <= 0 then
		return true
	elseif coalNeeded > 0 and turtle.getItemCount(1) == coalNeeded then
		turtle.select(1)
		turtle.refuel(coalNeeded)
		return true
	elseif coalNeeded > 0 and turtle.getItemCount(16) == 1 then
		pickItem(16,1,coalNeeded)
		turtle.select(1)
		turtle.refuel(coalNeeded)
		return true
	else
		print("Put "..tostring(coalNeeded).." coal in the first slot")
		return false
	end
end

local function digVertical()
	local arg = {}
	local cx, cy, cz = gps.locate()
	turtle.select(4)
	turtle.dropUp()
	if cy > goTo.y then	
		blocksv = cy - goTo.y
		while blocksv > 0 do
			while turtle.detectDown() do
				turtle.digDown()
				if turtle.getItemCount(4) < 1 then  --  making sure it is not lava
					break
				end
			end
			ensureVertical("down")
		end
	elseif cy < goTo.y then
		blocksv = goTo.y - cy
		while blocksv > 0 do
			while turtle.detectUp() do
				turtle.digUp()
				if turtle.getItemCount(4) < 1 then  --  making sure it is not lava
					break
				end
			end
			ensureVertical("up")
		end
	end
end

local function walk()
	local cx, cy, cz = gps.locate()
	if facingNorth() then
		digVertical()
		if goTo.z > cz then
			turn("right", 2)
			digAndWalk(math.abs(goTo.z - cz))
			if goTo.x > cx then
				turn("left",1)
				digAndWalk(math.abs(goTo.x - cx))
			elseif goTo.x < cx then
				turn("right", 1)
				digAndWalk(math.abs(goTo.x - cx))
			end
		elseif goTo.z < cz then
			digAndWalk(math.abs(goTo.z - cz))
			if goTo.x > cx then
				turn("right",1)
				digAndWalk(math.abs(goTo.x - cx))
			elseif goTo.x < cx then
				turn("left",1)
				digAndWalk(math.abs(goTo.x - cx))
			end
		elseif goTo.z == cz then  --- the z coordinates are the same!
			if goTo.x > cx then
				turn("right",1)
				digAndWalk(math.abs(goTo.x - cx))
			elseif goTo.x < cx then
				turn("left",1)
				digAndWalk(math.abs(goTo.x - cx))
			end
		end
	end
end

local function writeStr(arg) -- writeStr{color = colors.white, bgColor = colors.black, str = "Hi"}
	local color = arg.color or colors.white
	local str = arg.str
	local bgColor = arg.bgColor or colors.black
	term.setTextColor(color)
	term.setBackgroundColor(bgColor)
	print(str)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
end

local function checkArgs()
	if #tArgs < 3 or #tArgs > 3 then
		writeStr{color = colors.green, str = "Goto usages:"}
		writeStr{color = colors.green, str = "goto <x> <y> <z>"}
		return false
	elseif tonumber(tArgs[1]) and tonumber(tArgs[2]) and tonumber(tArgs[3]) then
		return true
	else
		writeStr{color = colors.green, str = "Goto usages:"}
		writeStr{color = colors.green, str = "goto <x> <y> <z>"}
		return false
	end
end

--- MAIN ACTION ---

if checkArgs() and checkFuel() then
	getFacing()
	facingNorth()
	walk()
end
