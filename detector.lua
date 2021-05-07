term.clear()
term.setCursorPos(1,1)
local detectorAug = peripheral.wrap("top")
print("This Detector's ID is:"..os.getComputerID())
local dSettings = settings.get("dSettings")
if not dSettings then
	print("What is the station ID?")
	local stationID = tonumber(read())
	print("Which platform am I in front of? Type a number")
	local platformNumber = tonumber(read())
	settings.set("dSettings", {stationID = stationID, platformNumber = platformNumber})
	settings.save(".settings")
	os.reboot()
end

rednet.open("front")
while true do
	event = os.pullEvent("redstone")
	local sTrainTag = detectorAug.getTag()
	if sTrainTag then
		local trainTag = textutils.unserialize(sTrainTag)
		local stationTag = {
			trainCargo = trainTag["trainCargo"],
			platformNumber = dSettings["platformNumber"],
			trainID = trainTag["trainID"],
		}
		rednet.send(dSettings["stationID"], stationTag)
	end
end