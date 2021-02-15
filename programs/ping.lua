-- pastebin get R4DKXbzm ping
-- std pb R4DKXbzm ping

function displayHelp()
	print("ping <url> <times>")
end

function averageTable(tab)
	temp = 0
	for a = 1, #tab do
		temp = temp + tab[a]
	end
	temp = temp / #tab
	return temp
end

tArg = {...}
url = tArg[1]
times = tonumber(tArg[2])
if not url then
	displayHelp()
	return false
end
if not times then times = 4 end

if times <= 0 then
	error("must be greater than 0.")
elseif times >= 200 then
	error("Seriously?")
end

if not string.find(url, "://") then
	url = "http://"..url
end

print("Pinging "..url.."...")
completeRatio = {}
pingList = {}
for a = 1, times do
	sleep(0)
	oldtime = os.time()
	b = http.get(url)
	newtime = os.time()
	diff = math.ceil((newtime - oldtime)*1000)
	table.insert(pingList, diff)
	write(" delay: "..diff.." ticks...("..a..")")
	if b then
		table.insert(completeRatio,1)
		print("")
	else
		table.insert(completeRatio,0)
		print("fail")
	end
end
print("done with "..(averageTable(completeRatio)*100).."% success")
print("average ping is "..(averageTable(pingList)).." ticks")