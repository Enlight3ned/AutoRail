term.clear()
term.setCursorPos(1,1)
local dispatchUserID = settings.get("dispatchUserID")

print("This Tagger's ID is: "..os.getComputerID())
if not dispatchUserID then
	print("What is the dispatch ID?")
	userInput = tonumber(read())
	settings.set("dispatchUserID", userInput)
	settings.save(".settings")
	os.reboot()
end
print("Waiting for dispatch...")
rednet.open("front")
local dispatchID
while true do
	dispatchID, dispatchPing = rednet.receive(1)
	if dispatchID == dispatchUserID and dispatchPing == "Ready?" then
		rednet.send(dispatchID, "Ready")
  break
	end
end
local detectorAug = peripheral.wrap("top")
term.clear()
term.setCursorPos(1,1)
print("Ready")
print("Waiting for trainTag")
local _,sTrainTag = rednet.receive()
term.clear()
term.setCursorPos(1,1)
print("trainTag received")
print("waiting for train overhead")
print("Press \"A\" to bypass")
repeat
	os.startTimer(1)
	local event,key = os.pullEvent()
	local r = rs.getAnalogInput("top")
until r ~= 0 or key == "a"
term.clear()
term.setCursorPos(1,1)
print("Train Overhead, setting tag")
print("Press \"B\" to bypass")
repeat
	os.startTimer(0.2)
	local event,key = os.pullEvent()
	print("tag")
	detectorAug.setTag(sTrainTag)
until rs.getAnalogInput("top") == 0 or key == "b" -- remember to change 1 to 0!
rednet.send(dispatchUserID, "Train has departed")
os.reboot()