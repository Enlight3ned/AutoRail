term.clear()
term.setCursorPos(1,1)
local cID = os.getComputerID()
textutils.slowPrint("This Switch's ID is: "..cID,100)
textutils.slowPrint("Waiting for HostPing...",100)
rednet.open("front")
while true do
	local HostID, HostPing = rednet.receive()
	if HostPing == "HostPing" then
		rednet.send(HostID, "Switch"..cID.."Ready")
		break
	else
	end
end
print("\nArmed")

-- Waits for host to send switch msg
while true do
	local _, hostSwitch = rednet.receive()
	if hostSwitch == "Switch" then

		redstone.setAnalogOutput("top",15)
	elseif hostSwitch == "UnSwitch" then
		redstone.setAnalogOutput("top",0)
	end
end