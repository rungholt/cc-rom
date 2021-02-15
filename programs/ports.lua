-- pastebin get XxkBiYJ6 ports
-- std pb XxkBiYJ6 ports
function getOpenChannels()
	modemChannels = {}
	sides = peripheral.getNames()
	modemSides = {}
	modemRednetSides = {}
	for a = 1, #sides do
		if peripheral.getType(sides[a]) == "modem" then
			table.insert(modemSides, sides[a])
			if rednet.isOpen(sides[a]) then
				table.insert(modemRednetSides, sides[a])
			end
		end
	end
	for a = 1, #modemSides do
		if not oldPeripheralWrap then
			modem = peripheral.wrap(modemSides[a])
		else
			modem = oldPeripheralWrap(modemSides[a])
		end
		channels = {}
		for b = 1, 65535 do
			if modem.isOpen(b) then
				table.insert(modemChannels, b)
			end
		end
	end
end

function printChannels()
	print("ID: " .. os.getComputerID())
	write("Open channels:")
	if isLocked then
		print(" LOCKED")
	else
		print("")
	end
	if modemChannels ~= nil then
		for a = 1, #modemChannels do
			if modemChannels[a] == rednet.CHANNEL_BROADCAST then
				print(" Rednet " .. modemChannels[a])
			else
				print(" Modem " .. modemChannels[a])
			end
		end
	else
		print(" none!")
	end
end

tArg = {...}

command = tArg[1]
argument1 = tArg[2]
argument2 = tArg[3]
argument3 = tArg[4]

getOpenChannels()

if not command then
	getOpenChannels()
	printChannels()
	return
elseif command == "open" then
	if tonumber(argument1) == nil then
		success = false
		for a = 1, #modemSides do
			if modemSides[a] == argument1 then
				success = true
			end
		end
		if argument1 == nil then
			error("no side given")
		end
		if success == true then
			rednet.open(argument1)
			print("Opened side " .. argument1 .. " on rednet")
		else
			error("modem " .. argument1 .. " not found")
		end
	else
		argument1 = tonumber(argument1)
		if argument1 <= 0 or argument1 > 65535 then
			error("channel '" .. argument1 .. "' not good")
		else
			modem.open(argument1)
			print("Opened channel " .. argument1)
		end
	end
elseif command == "close" then
	if tonumber(argument1) == nil then
		success = false
		if argument1 == "*" then
			modem.closeAll()
			print("All channels closed.")
		else
			for a = 1, #modemSides do
				if modemSides[a] == argument1 then
					success = true
				end
			end
			if argument1 == nil then
				error("no side given")
			end
			if success == true then
				rednet.close(argument1)
				print("Closed side '" .. argument1 .. "' on rednet")
			else
				error("modem '" .. argument1 .. "' not found")
			end
		end
	else
		argument1 = tonumber(argument1)
		if argument1 <= 0 or argument1 > 65535 then
			error("channel " .. argument1 .. " not good")
		else
			modem.close(argument1)
			print("Closed channel " .. argument1)
		end
	end
elseif command == "lock" then
	if not isLocked then
		oldOpenChannelList = modemChannels
		for a = 1, #modemSides do
			modem = peripheral.wrap(modemSides[a])
			modem.closeAll()
		end
		modem = nil
		oldRednetSend = rednet.send
		oldRednetBroadcast = rednet.broadcast
		oldPeripheralWrap = peripheral.wrap
		oldPeripheralFind = peripheral.find
		oldPeripheralCall = peripheral.call
		oldRednetLookup = rednet.lookup
		oldRednetHost = rednet.host
		oldRednetUnhost = rednet.unhost
		peripheral.wrap = function(object)
			if peripheral.getType(object) == "modem" then
				return nil
			else
				return oldPeripheralWrap(object)
			end
		end
		peripheral.find = function(object)
			if object == "modem" then
				return nil
			else
				return oldPeripheralFind(object)
			end
		end
		peripheral.call = function(...)
			arg = {...}
			if peripheral.getType(arg[1]) == "modem" then
				return nil
			else
				return oldPeripheralCall(...)
			end
		end
		rednet.send = function(id, contents, protocol)
			return nil
		end
		rednet.broadcast = function(contents, protocol)
			return nil
		end
		rednet.lookup = function(protocol, hostname)
			return nil
		end
		rednet.host = function(protocol, hostname)
			return nil
		end
		rednet.unhost = function(protocol, hostname)
			return nil
		end
		_G.peripheral.wrap = peripheral.wrap
		_G.peripheral.find = peripheral.find
		_G.peripheral.call = peripheral.call
		_G.rednet.send = rednet.send
		_G.rednet.broadcast = rednet.broadcast
		_G.rednet.lookup = rednet.lookup
		_G.rednet.host = rednet.host
		_G.rednet.unhost = rednet.unhost
		isLocked = true
		print("Modem communication is LOCKED.")
	else
		rednet.send = oldRednetSend
		rednet.broadcast = oldRednetBroadcast
		peripheral.wrap = oldPeripheralWrap
		peripheral.find = oldPeripheralFind
		peripheral.call = oldPeripheralCall
		rednet.lookup = oldRednetLookup
		rednet.host = oldRednetHost
		rednet.unhost = oldRednetUnhost
		_G.peripheral.wrap = peripheral.wrap
		_G.peripheral.find = peripheral.find
		_G.peripheral.call = peripheral.call
		_G.rednet.send = rednet.send
		_G.rednet.broadcast = rednet.broadcast
		_G.rednet.lookup = rednet.lookup
		_G.rednet.host = rednet.host
		_G.rednet.unhost = rednet.unhost
		isLocked = false
		modem = peripheral.find("modem")
		for a = 1, #oldOpenChannelList do
			modem.open(oldOpenChannelList[a])
		end
		modem = nil
		print("Modem communication is UNLOCKED.")
	end
elseif command == "listen" or command == "receive" then
	modem = peripheral.find("modem")
	if not modem then
		error("No modem to listen from!")
	end
	if not argument1 then
		argument1 = rednet.CHANNEL_BROADCAST
	end
	write("Listening on port "..argument1)
	if tonumber(argument2) then
		print(" for "..argument2.." sec...")
	else
		print("...")
	end
	if argument1 == "rednet" then
		modem.open(rednet.CHANNEL_BROADCAST)
		event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
	else
		modem.open(tonumber(argument1))
		event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
	end
	if event then
		print("msg: '"..message.."'")
		print("senderID: "..senderChannel)
		print("replyChannel: "..replyChannel)
		print("distance: "..senderDistance)
	else
		print("Nothing...")
	end
elseif command == "send" then
	modem = peripheral.find("modem")
	if not modem then
		error("Get a modem!")
	end
	if not argument1 then
		error("No message!")
	end
	if not argument2 then
		argument2 = rednet.CHANNEL_BROADCAST
	end
	if not argument3 then
		argument3 = rednet.CHANNEL_REPEAT
	end
	modem.open(tonumber(argument2))
	modem.transmit(tonumber(argument2),tonumber(argument3),argument1)
	print("Sent '"..argument1.."' on channel "..argument2.." (reply:"..argument3..")")
else
	print("//ports// - modem tool")
	print("Syntax:")
	print(" 'ports'")
	print(" 'ports [open/close] <sideName>'")
	print(" 'ports [open/close] <channelNum>'")
	print(" 'ports lock'")
	print(" 'ports send <message> [channel] [replyChannel]")
	print(" 'ports receive'")
end