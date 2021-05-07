term.clear()
term.setCursorPos(1,1)
rednet.open("top")
-- it's like print() but center (and maybe better)
local w,h = term.getSize()
function printCenter(y,s)
    local x = math.floor(w-string.len(s)) /2
    term.setCursorPos(x,y)
    term.clearLine()
    term.write(s)
end
function slowPrintCenter(y,s)
    local x = math.floor(w-string.len(s)) /2
    term.setCursorPos(x,y)
    term.clearLine()
    textutils.slowWrite(s)
end

-- get settings (if they don'event exist, it sets it to nil)
local sRoutes = settings.get("sRoutes")
local dSettings = settings.get("dSettings")
-- load APIs
if fs.exists("s.lua") == false then
	print("installing APIs...")
	term.setCursorPos(1,2)
	shell.run("pastebin get APF0HTE0 s.lua")
	sleep(2)
	os.reboot()
end
os.loadAPI("s.lua")
-- greet user if dispatcher hasn'event been run already
if not dSettings then
	printCenter(1, "\\\\ Welcome to Enlight3ned's auto dispatcher! //")
	printCenter(2, "Since this is your first time setting up")
	printCenter(3, "you will need to enter some info to setup")
	printCenter(4, "press enter to continue")
	repeat
		local _, choice = os.pullEvent("key")
		until choice == keys.enter
	term.clear()
	term.setCursorPos(1,1)
	print("What is the Tagger ID? This is shown when you boot one up")
	taggerID = tonumber(read())
	term.clear()
	term.setCursorPos(1,1)
	print("Now go to your tagger and set the ID to: "..os.getComputerID())
	print("press enter to continue")
	repeat
		local _,choice = os.pullEvent("key")
	until choice == keys.enter
	term.clear()
	term.setCursorPos(1,1)
	settings.set("dSettings", {taggerID = taggerID})
	settings.save(".settings")
	os.reboot()
end
-- new route function
local function newRoute(oldRoutes,editName)
	-- set variables
	local routes = {} -- table made of route tables
	local route = {} -- route table made with stops table, queued destin, and route name
	local stops = {} -- table of stops
	local eta 
	-- clear term and stuff
	term.clear()
	term.setCursorPos(1,1)
	-- get the route name
	local routeName
	if not editName then
		print("What would you like to call this route?")
		routeName = read()
		term.clear()
		term.setCursorPos(1,1)
	else
		routeName = editName
	end
	-- get number of stops
	print("How many junctions/pass-throughs does the train go\nthrough to get to the stop?\n(including the stop)")
	local numStops = tonumber(read())
	-- create table using stops table
	for i=1,numStops do
		term.clear()
		term.setCursorPos(1,1)
		-- ask for stops
		if i == numStops then
			print("What is the name of the stop?")
		else
			print("What is junction/pass-through "..i.."?")
		end
		stops[i] = read()
	end
	-- ask for destination after the stop
	term.clear()
	term.setCursorPos(1,1)
	-- create the table bro
	route = {stops = stops, routeName = routeName, eta = eta}
	-- now add to the existing routes table back (if it exists)
	if oldRoutes then
		-- put the old routes (if they exist) back into the routes table
		for i=1, #oldRoutes do
			table.insert(routes, i, oldRoutes[i])
		end
		-- then add the new route
		table.insert(routes, #oldRoutes + 1, route)
		-- but what if there is no oldRoutes? O:
	elseif not oldRoutes then
		table.insert(routes, 1, route)
		-- (what where you expecting? Im not some hackerman)
	end
	-- (cowboy accent) serialize damnit (thx Wojbie)
	local sRoutes = s.serializeRec(routes)
	-- set and save 
	settings.set("sRoutes", sRoutes)
	settings.save(".settings")
	os.reboot() -- "goodbye"
end

if not sRoutes then
	newRoute(nil)
end

local routes = textutils.unserialize(sRoutes)
--draw the UI
local function drawSelectionUI(onVal)
	term.clear()
	printCenter(1, "Please Select Route:")
	for i=1,#routes do
		if i == onVal then
			printCenter(math.floor(h/2)-7 + i,"[ "..routes[i]["routeName"].." ]")
		else
			printCenter(math.floor(h/2)-7 + i, routes[i]["routeName"])
		end
	end
	if onVal == #routes + 1 then
		printCenter(math.floor(h/2)-7 + #routes+1, "[ New Route ]")
	else
		printCenter(math.floor(h/2)-7 + #routes+1, "New Route")
	end
end

-- now get the user to select what they want to do
local userSet = 1
local function logic()
	while true do
		drawSelectionUI(userSet)
		local _, key = os.pullEvent("key")
		-- user input
		if key == keys.down then -- down arrow
			userSet = userSet + 1 
		elseif key == keys.up then -- up arrow
			userSet = userSet - 1 
		elseif key == keys.enter then -- enter
			return userSet, 1
		elseif key == keys.backspace then -- delete a route
			return userSet, 0
		elseif key == keys.e then -- edit a route
			return userSet, 2
		end
		if userSet > #routes + 1 then
			userSet = 1
		elseif userSet < 1 then
			userSet = #routes + 1
		end		
	end
end

local userChoice, option = logic()
local trainTag = {}
local trainCargo
-- what to do with userChoice
if userChoice == #routes + 1 and option == 1 then
	newRoute(routes)
elseif option == 0 then
	table.remove(routes,userChoice)
	local sRoutes = s.serializeRec(routes)
	settings.set("sRoutes", sRoutes)
	settings.save(".settings")
	os.reboot()
elseif option == 2 then
	local name = routes[userChoice]["routeName"]
	table.remove(routes,userChoice)
	newRoute(routes, name)
else
	-- print chosen destination
	term.clear()
	term.setCursorPos(1,1)
	print(routes[userChoice]["routeName"].." chosen")
	-- Ask for train contents
	sleep(2)
	print("What is the train's contents?")
	trainCargo = read()
end
-- create trainTag (kinda hard ngl)
local trainTag = {
	trainStops = routes[userChoice]["stops"],
	trainCargo = trainCargo,
	trainETA = routes[userChoice]["eta"],
	trainID = os.time(),
}
print(textutils.serialize(trainTag))
-- serialize trainTag to put on train
local sTrainTag = textutils.serialize(trainTag)

-- now send tag to detector augment using rednet

print("Waiting for Tagger "..dSettings["taggerID"])
rednet.open("top")
while true do
	rednet.send(dSettings["taggerID"], "Ready?")
	local _,ready = rednet.receive(1)
	if ready == "Ready" then
		break
	end
end
print("Tagger Ready")
sleep(1)
term.clear()
term.setCursorPos(1,1)
rednet.send(dSettings["taggerID"], sTrainTag)
print("sent tag to tagger")
-- wait for train to depart
sleep(1)
print("Waiting for train to depart...")
repeat
	local x, trainDeparted = rednet.receive(1)
until x == dSettings["taggerID"] and trainDeparted == "Train has departed"
-- send info to stations
print("train has departed, sending info to stations...")
-- create a table for stations to receive
local stationDepartedTrainInfo = {
	departedTrainCargo = trainCargo,
	departedTrainTo = routes[userChoice]["stops"],
	departedTrainETA = routes[userChoice]["eta"],
	departedTrainID = trainTag["trainID"],
}
sleep(1)
rednet.broadcast(stationDepartedTrainInfo)
print(textutils.serialize(stationDepartedTrainInfo))
print("sent, rebooting...")
sleep(5)
os.reboot()
