--[[
	Whisk - File/Folder Transmitter for ComputerCraft
	 by EldidiStroyrr

	Use the GUI by running w/o arguments
	
	get with
	 pastebin get 4ZRHE4Ar whisk
     std pb 4ZRHE4Ar whisk
     std ld whisk whisk

	Whisk is now on SimSoft! Install w/ storecode jVELp2st
--]]

local channel = 2846
local modem = peripheral.find("modem")

local yield = function()
	os.queueEvent("yield")
	os.pullEvent("yield")
end

local displayHelp = function()
	local helptxt = [[
Whisk - file/folder sender

Syntax:
 whisk
 whisk send <path> [idfilter] [password]
 whisk receive [path] [idfilter] [password]
]]
	write(helptxt)
end

fixstr = function(str) --replaces those annoying tabs with spaces, which fixes encryption
	if not type(str) == "string" then return str end
	local fix = string.gsub(str,string.char(9),"  ")
	return fix
end

local defaultKey = "swordfish" --the most secure.
local tArg = {...}
local mode, itPath, idfilter, enckey = tArg[1], tArg[2], tonumber(tArg[3]), tArg[4], tArg[5]
filetree = {}
if not enckey then
	enckey = defaultKey
end
if tArg[5] == "y" then
	doReadOnly = true
else
	doReadOnly = false
end

--API made by valithor.
local encrypt = function(msg,key)
	local num = ""
	for i = 1, #key do
		local let = key:sub(i,i):byte()
		num = let <= 9  and num.."99"..let or let<=99 and num.."9"..let or num..let
		num = #msg..num
	end
	math.randomseed(tonumber(num))
	local encrypt = ""
	for i = 1, #msg do
		local rotation = math.random(0,94)
		local byte = msg:sub(i,i):byte()
		local rotate = rotation+byte <= 127 and rotation +byte or ((rotation+byte)%127)+32
		encrypt = encrypt..string.char(rotate)
	end
	return encrypt
end

local decrypt = function(msg,key)
	local num = ""
	for i = 1, #key do
		local let = key:sub(i,i):byte()
		num = let <= 9 and num.."99"..let or let<=99 and num.."9"..let or num..let
		num = #msg..num
	end
	math.randomseed(tonumber(num))
	local decrypt = ""
	for i = 1, #msg do
		local rotation = math.random(0,94)
		local byte = msg:sub(i,i):byte()
		local rotate = byte-rotation >= 32 and byte-rotation or byte-rotation
		if rotate < 32 then
			rotate = rotate+95
		end
		decrypt = decrypt..string.char(rotate)
	end
	return decrypt
end

local tEnc = function(msg)
	return encrypt(encrypt(tostring(msg),enckey),tostring(math.floor(os.time()/2)))
end
local tDec = function(msg)
	return decrypt(decrypt(tostring(msg),enckey),tostring(math.floor(os.time()/2)))
end

listAll = function(_path, _files, noredundant) --Thanks Lyqyd!
	local path = _path or ""
	local files = _files or {}
	if #path > 1 then table.insert(files, path) end
	for _, file in ipairs(fs.list(path)) do
		local path = fs.combine(path, file)
		if fs.isDir(path) then
			listAll(path, files)
		else
			table.insert(files, path)
		end
	end
	if noredundant then
		for a = 1, #files do
			if fs.isDir(tostring(files[a])) then
				if #fs.list(tostring(files[a])) ~= 0 then
					table.remove(files,a)
				end
			end
		end
	end
	return files
end

local function choice(input)
	local event, button
	repeat
		event, button = os.pullEvent("key")
		if type(button) == "number" then button = keys.getName(button) end
		if button == nil then button = " " end
	until string.find(input, button)
	return button
end

local drawThing = function(text,y,t,b)
	local scr_x, scr_y = term.getSize()
	local _pt,_pb = term.getTextColor(), term.getBackgroundColor()
	if t then term.setTextColor(t) else term.setTextColor(colors.black) end
	if b then term.setBackgroundColor(b) else term.setBackgroundColor(colors.white) end
	term.setCursorPos(1,y-1)
	term.clearLine()
	term.setCursorPos((scr_x/2)-(#text/2),y)
	term.clearLine()
	print(text)
	term.clearLine()
	term.setTextColor(_pt)
	term.setBackgroundColor(_pb)
end

output = {}

local send = function()
	if not fs.exists(itPath) then
		error("No such file.")
	end
	contents = {}
	rawContents = {}
	if not fs.isDir(itPath) then
		local file = fs.open(itPath,"r")
		line = ""
		local s = 0
		while line do
			line = file.readLine()
			if line then
				table.insert(rawContents,fixstr(line))
				table.insert(contents,tEnc(fixstr(line)))
				if s >= 64 then
					yield()
					s = 0
				else
					s = s + 1
				end
			end
		end
		filetree = {[fs.getName(itPath)] = {fyle = contents, dir = false}}
		file.close()
		output = {id = os.getComputerID(), files = filetree}
	else
		filelist = {}
		_filelist = listAll(itPath,nil,true)
		if not doReadOnly then
			for a = 1, #_filelist do
				if not fs.isReadOnly(_filelist[a]) then
					table.insert(filelist,_filelist[a])
				end
			end
		else
			filelist = _filelist
		end
		for a = 1, #filelist do
			local isDir
			contents = {}
			rawContents = {}
			if not fs.isDir(filelist[a]) then
				local file = fs.open(filelist[a],"r")
				local line = ""
				local s = 0
				while line do
					line = file.readLine()
					if line then
						table.insert(contents,tEnc(fixstr(line)))
						table.insert(rawContents,fixstr(line))
						if s >= 64 then
							yield()
							s = 0
						else
							s = s + 1
						end
					end
				end
				file.close()
				isDir = false
			else
				contents = {""}
				isDir = true
			end
			if fs.combine("",shell.resolve(itPath)) == "" then --This oughta fix things
				filelist[a] = fs.combine("root"..os.getComputerID(),filelist[a])
			end
			filetree[filelist[a]] = {fyle = contents, dir = isDir}
		end
		output = {id = os.getComputerID(), files = filetree}
	end
	modem.transmit(channel,channel,output)
end
local receive = function(GUImode)
	local combinedSize = 0
	local filecount = 0
	--local event, side, sendID, repChannel, msg
	while true do
		input = {}
		event, side, sendChannel, repChannel, msg = os.pullEvent()
		if event == "char" and string.lower(side) == "x" then
			if not GUImode then
				print("Cancelled.")
			end
			return 0,0,false
		end
		if type(msg) == "table" then
			if type(msg.files) == "table" and (idfilter or msg.id) == msg.id then
				if GUImode then
					term.setBackgroundColor(colors.gray)
					term.clear()
					drawThing("Decrypting...",3)
				else
					print("Decrypting...")
				end
				break
			end
		end
	end
	for k,v in pairs(msg.files) do
		local fee
		if not itPath then
			fee = k
		else
			local slashpos = string.find(k,"/") or 1
			fee = fs.combine(itPath,k:sub(slashpos))
		end
		local doOverwrite = true
		if fs.exists(fee) and fee == k then
			if GUImode then
				drawThing("Overwrite '"..fee.."'? [Y/N]",6)
			else
				print("Overwrite '"..fee.."'? [Y/N]")
			end
			if choice("yn") == "n" then
				doOverwrite = false
			else
				doOverwrite = true
			end
		end
		if doOverwrite then
			filecount = filecount + 1
			if not fs.exists(fs.getDir(fee)) then fs.makeDir(fs.getDir(fee)) end
			if type(v) == "table" then
				if v.dir then
					fs.makeDir(fee)
				else
					local file = fs.open(fee,"w")
					if file then
						for a = 1, #v.fyle do
							file.writeLine(fixstr(tDec(v.fyle[a])))
							if a % 32 == 0 then
								yield()
							end
						end
						file.close()
						combinedSize = combinedSize + fs.getSize(fee)
					end
				end
			end
		end
	end
	return filecount, combinedSize, true
end

local sendGUI = function()
	term.setBackgroundColor(colors.gray)
	term.clear()
	drawThing("Which file/folder?",3)
	itPath = ""
	repeat
		term.setCursorPos(1,6)
		term.setTextColor(colors.black)
		term.setBackgroundColor(colors.lightGray)
		term.clearLine()
		write(">")
		sleep(0)
		itPath = read()
	until string.gsub(itPath," ","") ~= ""
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.gray)
	if not fs.exists(itPath) then 
		drawThing("Doesn't exist!",3)
		sleep(0.6)
		return false
	end
	drawThing("Encryption key? (optional)",3)
	enckey = nil
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	write(">")
	sleep(0)
	enckey = read("*")
	if enckey == "" then enckey = defaultKey end
	drawThing("ID filter? (optional)",3)
	idfilter = nil
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	write(">")
	sleep(0)
	idfilter = tonumber(read())
	drawThing("Do read-only files/folders? (Y/N)",3)
	doReadOnly = false
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	sleep(0)
	local thing = choice("yn")
	if thing == "y" then doReadOnly = true else doReadOnly = false end
	local thang = "Encrypting"
	if idfilter then
		thang = thang.." for ID "..tostring(idfilter).."..."
	else
		thang = thang.."..."
	end
	term.setBackgroundColor(colors.gray)
	term.clear()
	drawThing(thang,3)
	send()
	drawThing("Sent '"..itPath.."'!",3)
	sleep(0)
	return true
end

local receiveGUI = function()
	term.setBackgroundColor(colors.gray)
	term.clear()
	drawThing("Save as what? (optional)",3)
	itPath = nil
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	write(">")
	sleep(0)
	itPath = read()
	if string.gsub(itPath," ","") == "" then
		itPath = nil
	end
	drawThing("Decryption key? (optional)",3)
	enckey = nil
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	write(">")
	sleep(0)
	enckey = read("*")
	if enckey == "" then enckey = defaultKey end
	drawThing("Filter ID? (optional)",3)
	idfilter = nil
	term.setCursorPos(1,6)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	term.clearLine()
	write(">")
	sleep(0)
	idfilter = tonumber(read())
	local thang = "Receiving"
	if idfilter then
		thang = thang.." from ID "..tostring(idfilter).."..."
	else
		thang = thang.."..."
	end
	term.setBackgroundColor(colors.gray)
	term.clear()
	drawThing(thang,3)
	local count,size,success = receive(true)
	if success then
		drawThing("Received!",3)
		if count ~= 1 then
			drawThing("(Got "..count.." files)",5)
		else
			drawThing("(Got "..count.." file)",5)
		end
		if size ~= 1 then
			drawThing("(Totals "..size.." bytes)",7)
		else
			drawThing("(Totals "..size.." byte)",7)
		end
	else
		drawThing("Cancelled.",3)
	end
	sleep(0)
	return true
end

local gui = function()
	local scr_x, scr_y = term.getSize()
	local prevColor = term.getBackgroundColor()
	local evt = {}
	term.setBackgroundColor(colors.gray)
	term.clear()
	while true do
		term.setBackgroundColor(colors.gray)
		if res then term.clear() end
		drawThing("Whisk BETA",3)
		drawThing("(1) Send",7,colors.white,colors.black)
		drawThing("(2) Receive",11,colors.white,colors.black)
		drawThing("(X,Q) Exit",15,colors.white,colors.black)
		evt = {os.pullEvent()}
		local res = false
		sleep(0)
		if evt[1] == "mouse_click" then
			if evt[2] == 1 then
				if math.abs(evt[4] - 7) <= 1 then
					res = sendGUI()
				elseif math.abs(evt[4] - 11) <= 1 then
					res = receiveGUI()
				elseif math.abs(evt[4] - 15) <= 1 then
					res = true
				end
			end
		elseif evt[1] == "key" then
			if evt[2] == keys.one then
				res = sendGUI()
			elseif evt[2] == keys.two then
				res = receiveGUI()
			elseif evt[2] == keys.three or evt[2] == keys.q or evt[2] == keys.x then
				res = true
			end
		end
		if res then
			term.setCursorPos(1,scr_y)
			term.setBackgroundColor(prevColor)
			term.clearLine()
			break
		end
	end
end

if modem then modem.open(channel) end

waitForModem = function()
	while true do
		sleep(0)
		modem = peripheral.find("modem")
		if modem then
			return
		end
	end
end

if not tArg[1] then
	local prevBG, prevTXT = term.getBackgroundColor(), term.getTextColor()
	if modem then
		gui()
	else
		term.setBackgroundColor(colors.gray)
		term.clear()
		drawThing("You don't have a modem!",3)
		drawThing("Attach one or press a key.",5)
		sleep(0.1)
		local outcome = parallel.waitForAny(function() os.pullEvent("key") end, waitForModem)
		if modem then
			modem.open(channel)
			gui()
		else
			local scr_x,scr_y = term.getSize()
			term.setCursorPos(1,scr_y)
			term.setBackgroundColor(prevBG)
			term.setTextColor(prevTXT)
			term.clearLine()
			sleep(0)
			return false
		end
	end	
else
	if not modem then
		error("No modem detected.")
	end
	if mode == "send" then
		send()
	elseif mode == "receive" then
		write("Receiving")
		if idfilter then
			print(" from "..idfilter.."...")
		else
			print("...")
		end
		local fc, size = receive(false)
		write("Done. (got "..fc.." file")
		if fc ~= 1 then write("s") end
		write(", totalling "..size.." byte")
		if size ~= 1 then print("s)") else print(")") end
	else
		displayHelp()
	end
end

sleep(0)