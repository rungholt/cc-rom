--[[ lsa: List Advanced
	Allows the display of hidden files and file sizes
	By Nitrogen Fingers
]]--

local tArgs = {...}
local paths = {}
local files = {}
local errors = {}
local _long, _all = false, false
local w, h = term.getSize()
local _,cy = term.getCursorPos()
local _maxlen, _maxsize, _maxdrive = 0,0,0

--Performs a screen-specific print that will throw an event if the bottom of the screen is reached.
--Doesn't do any wrapping, so make sure the string is the right size
local function lprint(str, col)
	if term.isColour() and col then term.setTextColour(col)
	else term.setTextColour(colours.white) end
	if cy == 1 then
		os.pullEvent("key")
		_,cy = term.getCursorPos()
	end
	local _,_yold = term.getCursorPos()
	print(str)
	local _,_ynew = term.getCursorPos()
	cy = cy - 1 + (_ynew - _yold)
end

--Gets the combined size of a given directory
local function calculateDirectorySize(_fullpath)
	local _size = 0
	local _list = fs.list(_fullpath)
	for i=1,#_list do
		local _newPath = _fullpath.."/".._list[i]
		if fs.isDir(_newPath) then
			_size = _size + calculateDirectorySize(_newPath)
		else
			_size = _size + fs.getSize(_newPath)
		end
	end
	return _size
end

--Figures out the spacing for the columns in a long print
--There's a memory inefficiency here; we're doing a recursive call twice.
--But really, meh.
local function calculateColumnWidths(_list, _path)
	for i=1,#_list do
		local _fullpath = shell.resolve(_path).."/".._list[i]
		if fs.isDir(_fullpath) and _long then
			_maxsize = math.max(_maxsize, #tostring(calculateDirectorySize(_fullpath)))
		elseif _long then
			_maxsize = math.max(_maxsize, #tostring(fs.getSize(_fullpath)))
		end
		if _list[i]:sub(1,1) ~= "." or _all then
			_maxlen = math.max(_maxlen, #_list[i])
			_maxdrive = math.max(_maxdrive, #fs.getDrive(_fullpath))
		end
	end
end

local function printUsageInfo()
	lprint("Usage: ls [option]... [path]...")
	lprint("Lists all files in the specified directories. Files are sorted by type and alpabetically")
	lprint("-l		use long listing format")
	lprint("-a		do not ignore entries starting with \'.\'")
	lprint("-h		display usage info")
end

local function printListing(_list, _path)
	local _files = {}
	for i=#_list,1,-1 do
		local _fullPath = shell.resolve(_path).."/".._list[i]
	
		if not _all and _list[i]:sub(1,1) == "." then
			table.remove(_list, i)
		elseif not fs.isDir(_fullPath) then
			table.insert(_files, table.remove(_list, i))
		end
	end
	table.sort(_files)
	table.sort(_list)
	
	local _c = ""
	if _long then
		for i=1,#_list do
			local _fullPath = shell.resolve(_path).."/".._list[i]
			local _size = tostring(calculateDirectorySize(_fullPath))
			term.setTextColour(colours.white)
			local _read = "d"
			if fs.isReadOnly(_fullPath) then _read = _read.."-" else _read = _read.."w" end
			local _drive = fs.getDrive(_fullPath)
			term.write(_read.." "..string.rep(" ", _maxsize - #_size).._size.." ".._drive..
					string.rep(" ", _maxdrive - #_drive + 1))
			if term.isColour() then term.setTextColour(colours.green) end
			term.write(_list[i])
			lprint("")
		end
		for i=1,#_files do
			local _fullPath = shell.resolve(_path).."/".._files[i]
			local _size = tostring(fs.getSize(_fullPath))
			local _read = "f"
			local _drive = fs.getDrive(_fullPath)
			if fs.isReadOnly(_fullPath) then _read = _read.."-" else _read = _read.."w" end
			lprint(_read.." "..string.rep(" ", _maxsize - #_size).._size.." ".._drive..
					string.rep(" ", _maxdrive - #_drive + 1).._files[i], colours.white)
		end
	else
		for i=1,#_list do
			if #_c + _maxlen + 1 > w then
				lprint(_c, colours.green)
				_c = ""
			end
			_c = _c.._list[i]..string.rep(" ", _maxlen - #_list[i] + 1)
		end
		if _c ~= "" then 
			lprint(_c, colours.green) 
			_c = ""
		end
		for i=1,#_files do
			if #_c + _maxlen + 1 > w then
				lprint(_c, colours.white)
				_c = ""
			end
			_c = _c.._files[i]..string.rep(" ", _maxlen - #_files[i] + 1)
		end
		if _c ~= "" then lprint(_c, colours.white) end
	end
end

for i=1,#tArgs do
	if tArgs[i]:sub(1,1) == "-" then
		if #paths > 0 or #files > 0 then
			table.insert(errors, "Option "..tArgs[i].." found after path")
		end
	
		for j=2,#tArgs[i] do
			local _comm = tArgs[i]:sub(j,j)
			if _comm == "l" then
				_long = true
			elseif _comm == "a" then
				_all = true
			elseif _comm == "h" then
				printUsageInfo()
				return
			else
				table.insert(errors, "Unrecognized option \'"..tArgs[i].."\'. Use -h for help.")
			end
		end
	else
		if not fs.exists(shell.resolve(tArgs[i])) then
			table.insert(errors, "No such file or directory: "..tArgs[i])
		elseif fs.isDir(shell.resolve(tArgs[i])) then
			table.insert(paths, tArgs[i])
			calculateColumnWidths(fs.list(shell.resolve(tArgs[i])), tArgs[i])
		else
			table.insert(files, tArgs[i])
			_maxlen = math.max(_maxlen, #tArgs[i])
			_maxsize = math.max(_maxsize, #tostring(fs.getSize(shell.resolve(tArgs[i]))))
			_maxdrive = math.max(_maxdrive, #fs.getDrive(shell.resolve(tArgs[i])))
		end
	end
end

if #paths == 0 and #files == 0 then 
	table.insert(paths, ".") 
	calculateColumnWidths(fs.list(shell.resolve(".")), ".")
end
for _,err in pairs(errors) do lprint(err, colours.red) end
if #errors > 0 then 
	return
end


if #files > 0 then
	printListing(files, ".")
	if #paths > 0 then lprint("") end
end

for i=1,#paths do
	if #paths > 1 or #files > 1 then lprint(paths[i]..":") end
	printListing(fs.list(shell.resolve(paths[i])), paths[i])
	if i ~= #paths then lprint("") end
end