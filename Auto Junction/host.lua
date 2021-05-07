term.clear()
term.setCursorPos(1,1)

-- setup the switches if the user hasn't already
local numSwitches = settings.get("numSwitches")
if not settings.get("numSwitches") then
    print("How many switches does this junction have?")
     settings.set("numSwitches", tonumber(read()))
     settings.save(".settings")
     os.reboot()
 end

if not settings.get("UserSet") then
    local switchTable = {}
    for i=1,numSwitches do
        print("Switch "..i..":")
        print("What is the name of the line\nthat the train is coming from?")
        local settingName = read()
        print("What is the ID of the detector before this switch?")
        local detectorID = tonumber(read())
        print("What is the ID of the Switch?")
        local switchID = tonumber(read())
        print("What line does this switch direct to when active?")
        local switchTo = read()
        term.clear()
        term.setCursorPos(1,1)
        print("Switch "..settingName.." Summery:")
        print("DetectorID: "..detectorID)
        print("switchID: "..switchID)
        print("Switches to: "..switchTo)
        print("Is this correct? [y/n]")
        local choice = read()
        if choice == "y" or choice == "yes" then
            switchTable[i] = {detectorID = detectorID,switchID = switchID,switchTo = switchTo, settingName = settingName} -- change here
            term.clear()
            term.setCursorPos(1,1)
        else
            os.reboot()
        end
    end
    settings.set("switchTable", switchTable)
    settings.set("UserSet", true)
    settings.save(".settings")
    os.reboot()
end

local switchTable = settings.get("switchTable")
textutils.slowPrint("User Settings loaded", 30)

-- wait for switches (To let the Chunks load)

rednet.open("top")
for i=1,#switchTable do
   print("Pinging detector "..switchTable[i]["settingName"])
   -- commented out for now
   while true do
		rednet.send(switchTable[i]["detectorID"], "HostPing")
		local _, detectorPing = rednet.receive(1)
		if detectorPing == "Detector"..switchTable[i]["detectorID"].."Ready" then
	    	print("\n"..detectorPing)
	    	break
		else 
		end
	end
end
term.clear()
term.setCursorPos(1,1)
print("All Detectors Ready Pinging Switches")

for i=1,#switchTable do
   print("Pinging switch "..switchTable[i]["settingName"])
   while true do
    	rednet.send(switchTable[i]["switchID"], "HostPing")
    	local _,  switchPing = rednet.receive(1)
    	if switchPing == "Switch"..switchTable[i]["switchID"].."Ready" then
        	print("\n"..switchPing)
        	break
    	else 
    	end
    end
end

term.clear()
term.setCursorPos(1,1)
print("System Ready")
print("Waiting for trains")


-- at this point, all the switches are ready
-- now we need to wait for one of the detectors to send a train tag

-- reset all switches if we need to (which we don't but it's here anyway)
local function resetSwitches()
	for i=1, #switchTable do
		rednet.send(switchTable[i]["switchID"],"UnSwitch")
	end
end

-- decide what to do when the trainTag is received
-- This is basically the entire switch logic (small right?)
while true do
	local _, trainTag = rednet.receive()
	for i=1, #switchTable do
		for a=1, #trainTag["trainStops"] do
			if switchTable[i]["switchTo"] == trainTag["trainStops"][a] then
				print("switching")
				rednet.send(switchTable[i]["switchID"], "Switch")
			else
				rednet.send(switchTable[i]["switchID"], "UnSwitch")
				print("Unswitching")
			end
		end
	end
end






