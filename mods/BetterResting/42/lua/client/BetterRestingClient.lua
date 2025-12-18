-- BetterResting Client-side Script
-- Handles UI feedback and messages

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    require "BetterRestingShared"
end

-- Track buff states on client
local clientBuffData = {
    chairBuffActive = false,
    lastIndicatorTime = 0,
    indicatorInterval = 30, -- Show indicator every 30 seconds while buff is active
}

-- Show buff messages
local function showBuffMessage(buffType, duration, buffEndTime)
    print("BetterResting [CLIENT] showBuffMessage called - buffType: " .. tostring(buffType) .. ", duration: " .. tostring(duration))
    if buffType == "chair" then
        local player = getPlayer()
        print("BetterResting [CLIENT] Player found: " .. tostring(player ~= nil))
        if player then
            local durationText = ""
            if duration then
                durationText = " (" .. duration .. " minutes)"
            end
            local message = "Well Rested! Reduced stamina consumption" .. durationText
            print("BetterResting [CLIENT] Showing message: " .. message)
            -- Show green text above player
            HaloTextHelper.addText(player, message, HaloText.getColorGreen())
            print("BetterResting [CLIENT] HaloTextHelper.addText called")
            -- Mark buff as active
            clientBuffData.chairBuffActive = true
            clientBuffData.lastIndicatorTime = 0 -- Reset timer so indicator shows immediately
            
            -- Store end time in shared data (already done by server, but update local if provided)
            if buffEndTime and BetterResting.ClientBuffData then
                BetterResting.ClientBuffData.chairBuffEndTime = buffEndTime
            end
            print("BetterResting [CLIENT] Buff activated - Active: " .. tostring(clientBuffData.chairBuffActive))
        else
            print("BetterResting [CLIENT] ERROR: getPlayer() returned nil!")
        end
    end
end

-- Show buff expired message
local function showBuffExpired(buffType)
    if buffType == "chair" then
        local player = getPlayer()
        if player then
            HaloTextHelper.addText(player, "Rested feeling fades...", HaloText.getColorRed())
            clientBuffData.chairBuffActive = false
        end
    end
end

-- Receive buff messages from server
Events.OnClientCommand.Add(function(module, command, args)
    print("BetterResting [CLIENT] OnClientCommand received - module: " .. tostring(module) .. ", command: " .. tostring(command))
    if module == "BetterResting" and command == "ShowBuffMessage" then
        print("BetterResting [CLIENT] Processing ShowBuffMessage")
        showBuffMessage(args.buff, args.duration, args.buffEndTime)
    elseif module == "BetterResting" and command == "BuffExpired" then
        print("BetterResting [CLIENT] Processing BuffExpired")
        showBuffExpired(args.buff)
    end
end)

-- Show rest location feedback (optional)
local lastRestType = nil

-- Main update loop - check buff status and show indicators
local updateCounter = 0
Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    updateCounter = updateCounter + 1
    -- Only log every 300 updates (roughly every 5 seconds) to avoid spam
    if updateCounter % 300 == 0 then
        print("BetterResting [CLIENT] Update loop running - Update #" .. updateCounter)
    end
    
    local restType = BetterResting.detectRestType(player)
    
    -- Show message when rest type changes (first time only)
    if restType ~= lastRestType and restType ~= BetterResting.RestType.FLOOR then
        print("BetterResting [CLIENT] Rest type changed to: " .. tostring(restType))
        local messages = {
            [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
            [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
            [BetterResting.RestType.BED] = "Resting in bed - Health and muscle recovery",
        }
        
        if messages[restType] then
            print("BetterResting [CLIENT] Showing rest message: " .. messages[restType])
            HaloTextHelper.addText(player, messages[restType], HaloText.getColorBlue())
        end
    end
    
    lastRestType = restType
    
    -- Check if buff should be active (use shared data for single player compatibility)
    local buffShouldBeActive = clientBuffData.chairBuffActive
    
    -- Check shared global data (works in single player where server sets this)
    if BetterResting.ClientBuffData then
        if BetterResting.ClientBuffData.chairBuffActive then
            local currentGameHours = BetterResting.getCurrentGameHours()
            if updateCounter % 300 == 0 then
                print("BetterResting [CLIENT] Checking buff - Current hours: " .. currentGameHours .. ", End time: " .. BetterResting.ClientBuffData.chairBuffEndTime)
            end
            if currentGameHours < BetterResting.ClientBuffData.chairBuffEndTime then
                buffShouldBeActive = true
                -- Sync client data
                if not clientBuffData.chairBuffActive then
                    print("BetterResting [CLIENT] Syncing buff state - activating client buff")
                    clientBuffData.chairBuffActive = true
                    clientBuffData.lastIndicatorTime = 0
                end
            else
                -- Buff expired
                if clientBuffData.chairBuffActive then
                    print("BetterResting [CLIENT] Buff expired!")
                    showBuffExpired("chair")
                end
                BetterResting.ClientBuffData.chairBuffActive = false
            end
        else
            -- Buff not active in shared data
            if clientBuffData.chairBuffActive then
                print("BetterResting [CLIENT] Buff deactivated in shared data")
                clientBuffData.chairBuffActive = false
            end
        end
    end
    
    -- Show periodic indicator while buff is active
    if buffShouldBeActive then
        local currentTime = Calendar.getInstance():getTimeInMillis() / 1000 -- Current time in seconds
        local timeSinceLastIndicator = currentTime - clientBuffData.lastIndicatorTime
        
        -- Show indicator every 30 seconds
        if timeSinceLastIndicator >= clientBuffData.indicatorInterval then
            print("BetterResting [CLIENT] Showing periodic indicator - 'I feel well rested'")
            HaloTextHelper.addText(player, "I feel well rested", HaloText.getColorGreen())
            clientBuffData.lastIndicatorTime = currentTime
        end
    end
end)

print("BetterResting client script loaded")
if writeLog then
    writeLog("BetterResting", "Client script loaded")
end

-- Verify client script loaded with event
Events.OnGameStart.Add(function()
    print("BetterResting [CLIENT] OnGameStart - Client script confirmed loaded!")
    print("BetterResting [CLIENT] Checking if BetterResting namespace exists: " .. tostring(BetterResting ~= nil))
    if BetterResting then
        print("BetterResting [CLIENT] BetterResting.detectRestType exists: " .. tostring(type(BetterResting.detectRestType) == "function"))
        print("BetterResting [CLIENT] BetterResting.getCurrentGameHours exists: " .. tostring(type(BetterResting.getCurrentGameHours) == "function"))
    end
end)