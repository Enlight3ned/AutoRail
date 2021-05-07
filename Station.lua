term.clear()
term.setCursorPos(1,1)
local display = peripheral.wrap("right")
local speaker = peripheral.wrap("bottom")
display.clear()
local modem = peripheral.wrap("top")
modem.open(os.getComputerID())
modem.open(65535) -- rednet broadcast channel
local function displayWrite(y,color,s)
	local x,_ = display.getCursorPos()
	display.setCursorPos(x,y)
	display.setTextColor(color)
	display.write(s)
end
local function clearLine(y)
	display.setCursorPos(1,y)
	display.clearLine()
end
local sSettings = settings.get("sSettings")

if not sSettings then
	print("What is the name of this Station? Name must be different from all other stations")
	local stationName = read()
	print("How many platforms are at this station?")
	local numPlatforms = tonumber(read())
	local platformIDs = {}
	for i=1,numPlatforms do
		term.clear()
		term.setCursorPos(1,1)
		print("What is the ID of the detector in front of platform "..i.."?")
		local platformID = tonumber(read())
		platformIDs[i] = platformID
	end
	term.clear()
	term.setCursorPos(1,1)
	settings.set("sSettings", {platformIDs = platformIDs, stationName = stationName})
	settings.save(".settings")
	os.reboot()
end

local function infoReceive()
	local timerID = os.startTimer(10)
	local event,_,_,id,message,distance = os.pullEvent()
	if message == nil then return end
	os.cancelTimer(timerID)
	-- what to do with received info
	-- check if the message is from a detector, if it is then returns true and message
	for i=1,#sSettings["platformIDs"] do
		if id == sSettings["platformIDs"][i] then
			return true, message.message
		end
	end
	-- if you got here then that means that the message didn't come from a detector
	return false, message.message, distance
end
-- create tables
local timeTable = {}
local stationTable = {}
local function infoInterpret()
	local isDetector,message,distance = infoReceive() -- waits for one second for a message
	-- print(isDetector,message,distance)
	if isDetector == false and message ~= nil then -- message is from a dispatcher from another station
		for i=1,#message["departedTrainTo"] do -- check if departed train has this station in its route
			if message["departedTrainTo"][i] == sSettings["stationName"] then
				-- calculate ETA based on distance
				timeTable[#timeTable + 1] = {
					incomeTrainCargo = message["departedTrainCargo"],
					incomeTrainETA = math.ceil(distance/1000),
					incomeTrainID = message["departedTrainID"],
					incomeTrainAdded = os.epoch("utc"),
				}
				return "incomingTrain", true
			end
		end
		return "incomingTrain", false
	end
	if isDetector == true and type(message) == "table" then -- message is from a detector
		stationTable[#stationTable + 1] = {
			stationCargo = message["trainCargo"],
			platform = message["platformNumber"],
			trainID = message["trainID"],
			timeArrived = os.epoch("utc"),
		}
		for i=#timeTable,1,-1 do -- check for id and remove from timeTable
			if timeTable[i]["incomeTrainID"] == message["trainID"] then
				table.remove(timeTable,i)
			end
		end
	end
end
-- 1000 IQ moment
local function calcETA(epoch, ETA)
	local cTime = os.epoch("utc")/60000 -- quick maths
	local aTime = epoch / 60000
	local timePassed = cTime - aTime -- in minutes
	local calcTime = math.ceil(ETA - timePassed)
	return calcTime
end

-- remove from station table after some time
local function stationTimeCheck()
	for i=1,#stationTable do
		if calcETA(stationTable[i]["timeArrived"], 1) <=0 then
			stationTable[i] = nil
		end
	end
end

local function notify()
	local notes = {5,0,9}
	for i=1, #notes do
		speaker.playNote("pling", 3,notes[i])
		sleep(0.2)
	end
end
-- draw screen
while true do
	stationTimeCheck()
	local test = infoInterpret()
	display.clear()
	term.clear()
	term.setCursorPos(1,1)
	print(textutils.serialize(timeTable))
	print(textutils.serialize(stationTable))
	for i=1,#timeTable do -- Time Table
		clearLine(i)
		displayWrite(i, colors.red, timeTable[i]["incomeTrainCargo"])
		displayWrite(i, colors.white, " --> ")
		displayWrite(i, colors.lightBlue,timeTable[i]["incomeTrainID"])
		displayWrite(i, colors.white, " ETA. ")
		displayWrite(i, colors.orange, calcETA(timeTable[i]["incomeTrainAdded"], timeTable[i]["incomeTrainETA"]).."min")
	end

	if test then notify() end

	display.setCursorPos(1,#timeTable+1)
	displayWrite(#timeTable+1, colors.white,string.rep("\152",30))
	for i=1,#stationTable do
		local x = #timeTable+2
		clearLine(x)
		displayWrite(x, colors.green,"Platform "..stationTable[i]["platform"]..": ")
		displayWrite(x, colors.yellow, stationTable[i]["trainID"])
	end

end
