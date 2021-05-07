term.clear()
term.setCursorPos(1,1)
local cID = os.getComputerID()
print("This Detector's ID is: "..cID)
print("Waiting for HostPing...")
rednet.open("front")
local HostID, HostPing
while true do
	HostID, HostPing = rednet.receive()
	if HostPing == "HostPing" then
		rednet.send(HostID, "Detector"..cID.."Ready")
		print(HostID)
		break
	else print("Interferance or HostPing not correct")
	end
end
print("\nReady, waiting for train_overhead...")
local augDetect = peripheral.wrap("top")
while true do
	sleep(0.3)
	local sTrainTag = augDetect.getTag()
	if trainTag then
		print(trainTag)
		local trainTag = textutils.unserialize(sTrainTag)
		rednet.send(HostID, trainTag)
	else	
	end
end