-- BetterResting Client-side Script
-- Handles UI feedback and messages only
-- Game mechanics are handled by server script (BetterRestingServer.lua)

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    require "BetterRestingShared"
end

-- Track last rest type for UI messages only
local lastRestType = nil

-- Track buff states on client (for UI)
local clientBuffData = {
    chairBuffActive = false,
    lastIndicatorTime = 0,
    indicatorInterval = 30, -- Show indicator every 30 seconds while buff is active
}

-- Track if we've shown the initial confirmation message
local hasShownInitialMessage = false
local confirmationTimer = 0

-- Show buff messages (triggered when server sets buff)
local function showBuffMessage(buffType, duration, buffEndTime)
    if buffType == "chair" then
        local player = getPlayer()
        if player then
            local durationText = ""
            if duration then
                durationText = " (" .. duration .. " minutes)"
            end
            local message = "Well Rested! Reduced stamina consumption" .. durationText
            -- Show green text above player (using RGB: 0, 255, 0 for green)
            HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
            -- Mark buff as active
            clientBuffData.chairBuffActive = true
            clientBuffData.lastIndicatorTime = 0 -- Reset timer so indicator shows immediately
        end
    end
end

-- Show buff expired message
local function showBuffExpired(buffType)
    if buffType == "chair" then
        local player = getPlayer()
        if player then
            HaloTextHelper.addTextWithArrow(player, "Rested feeling fades...", true, 255, 0, 0)
            clientBuffData.chairBuffActive = false
        end
    end
end

-- Show rest location feedback (optional)
-- Track message display for extended duration
local restMessageData = {
    startTick = 0,
    message = nil,
    duration = 600, -- Display for 10 seconds (600 ticks at 60 ticks/sec)
    refreshInterval = 60, -- Refresh every 1 second (60 ticks)
    lastRefresh = 0
}

-- Game mechanics removed - handled by server script

-- Main update loop - handles UI only (game mechanics on server)
local updateCounter = 0
Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    updateCounter = updateCounter + 1
    
    -- Show confirmation message after a short delay (once)
    if not hasShownInitialMessage then
        confirmationTimer = confirmationTimer + 1
        if confirmationTimer >= 60 then -- Wait ~1 second (60 ticks)
            showModConfirmation()
        end
    end
    
    -- Detect rest type for UI messages only
    local restType = BetterResting.detectRestType(player)
    
    -- Debug logging for rest type detection
    if restType ~= lastRestType then
        print("[BetterResting CLIENT] Rest type changed: " .. tostring(lastRestType) .. " -> " .. tostring(restType))
    end
    
    -- Check for buff activation (server sets this in BetterResting.ClientBuffData)
    if BetterResting.ClientBuffData and BetterResting.ClientBuffData.chairBuffActive then
        local currentGameHours = BetterResting.getCurrentGameHours()
        local endTime = BetterResting.ClientBuffData.chairBuffEndTime
        
        -- Check if buff just activated (wasn't active before)
        if not clientBuffData.chairBuffActive and endTime > currentGameHours then
            local remaining = endTime - currentGameHours
            local remainingMinutes = math.floor(remaining * 60)
            showBuffMessage("chair", remainingMinutes, endTime)
        end
        
        -- Check if buff expired
        if clientBuffData.chairBuffActive and currentGameHours >= endTime then
            showBuffExpired("chair")
        end
        
        clientBuffData.chairBuffActive = BetterResting.ClientBuffData.chairBuffActive
    elseif clientBuffData.chairBuffActive then
        -- Buff no longer active
        clientBuffData.chairBuffActive = false
    end
    
    -- UI: Show message when rest type changes (first time only)
    if restType ~= lastRestType and restType ~= BetterResting.RestType.FLOOR then
        local messages = {
            [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
            [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
            [BetterResting.RestType.BED] = "Resting in bed - Wounds and muscle strain",
        }
        
        if messages[restType] then
            print("[BetterResting CLIENT] Showing message for rest type: " .. tostring(restType) .. " - " .. messages[restType])
            -- Start extended message display (reset timer when type changes)
            restMessageData.startTick = updateCounter
            restMessageData.message = messages[restType]
            restMessageData.lastRefresh = updateCounter
            HaloTextHelper.addTextWithArrow(player, messages[restType], true, 0, 100, 255)
        else
            print("[BetterResting CLIENT] WARNING: No message found for rest type: " .. tostring(restType))
        end
    end
    
    -- Refresh message periodically for extended display duration
    -- Always use current rest type's message to ensure it's up to date
    if restType ~= BetterResting.RestType.FLOOR then
        local messages = {
            [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
            [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
            [BetterResting.RestType.BED] = "Resting in bed - Wounds and muscle strain",
        }
        
        local currentMessage = messages[restType]
        if currentMessage then
            -- Update stored message to current rest type
            restMessageData.message = currentMessage
            
            local elapsed = updateCounter - restMessageData.startTick
            if elapsed < restMessageData.duration then
                -- Refresh message at intervals to keep it visible
                if updateCounter - restMessageData.lastRefresh >= restMessageData.refreshInterval then
                    HaloTextHelper.addTextWithArrow(player, currentMessage, true, 0, 100, 255)
                    restMessageData.lastRefresh = updateCounter
                end
            else
                -- Duration expired, clear message
                restMessageData.message = nil
            end
        end
    else
        -- Clear message when no longer resting
        restMessageData.message = nil
    end
    
    -- Reset stamina check timer
    if restType == BetterResting.RestType.FLOOR then
        lastStaminaCheck = updateCounter
    end
    
    lastRestType = restType
    
    -- Show periodic indicator while buff is active
    if clientBuffData.chairBuffActive then
        local currentTime = Calendar.getInstance():getTimeInMillis() / 1000 -- Current time in seconds
        local timeSinceLastIndicator = currentTime - clientBuffData.lastIndicatorTime
        
        -- Show indicator every 30 seconds
        if timeSinceLastIndicator >= clientBuffData.indicatorInterval then
            HaloTextHelper.addTextWithArrow(player, "I feel well rested", true, 0, 255, 0)
            clientBuffData.lastIndicatorTime = currentTime
        end
    end
end)

print("BetterResting client script loaded")
if writeLog then
    writeLog("BetterResting", "Client script loaded")
end

-- Initialize and show confirmation on game start
local function initBetterResting()
    local player = getPlayer()
    if not player then return end
    
    -- Show confirmation message
    if not hasShownInitialMessage then
        HaloTextHelper.addTextWithArrow(player, "BetterResting Mod Loaded!", true, 0, 255, 0)
        hasShownInitialMessage = true
    end
end

-- Global function for testing from Lua console
BetterRestingTest = {}
function BetterRestingTest.showMessage(msg)
    local player = getPlayer()
    if not player then
        print("BetterRestingTest: No player found!")
        return false
    end
    if not HaloTextHelper then
        print("BetterRestingTest: HaloTextHelper not found!")
        return false
    end
    local message = msg or "BetterResting Mod Test Message!"
    HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
    print("BetterRestingTest: Message displayed: " .. message)
    return true
end

function BetterRestingTest.checkMod()
    print("=== BetterResting Mod Diagnostic ===")
    print("BetterResting namespace exists: " .. tostring(BetterResting ~= nil))
    if BetterResting then
        print("BetterResting.Version: " .. tostring(BetterResting.Version))
        print("BetterResting.ModID: " .. tostring(BetterResting.ModID))
        print("BetterResting.detectRestType exists: " .. tostring(type(BetterResting.detectRestType) == "function"))
        print("BetterResting.getCurrentGameHours exists: " .. tostring(type(BetterResting.getCurrentGameHours) == "function"))
    end
    
    local player = getPlayer()
    print("getPlayer() result: " .. tostring(player ~= nil))
    if player then
        print("Player name: " .. tostring(player:getUsername()))
        
        -- Check current rest type
        if BetterResting then
            local restType = BetterResting.detectRestType(player)
            print("Current rest type: " .. tostring(restType))
        end
        
        -- Check buff status
        if BetterResting and BetterResting.ClientBuffData then
            if BetterResting.ClientBuffData.chairBuffActive then
                local currentHours = BetterResting.getCurrentGameHours()
                local endTime = BetterResting.ClientBuffData.chairBuffEndTime
                local remaining = endTime - currentHours
                local remainingMinutes = math.floor(remaining * 60)
                print("Well Rested buff: ACTIVE")
                print("  Remaining time: " .. remainingMinutes .. " minutes")
                print("  Expires at game hour: " .. endTime)
            else
                print("Well Rested buff: INACTIVE")
            end
        end
    end
    
    print("HaloTextHelper exists: " .. tostring(HaloTextHelper ~= nil))
    print("HaloText exists: " .. tostring(HaloText ~= nil))
    if HaloText then
        print("HaloTextHelper.addTextWithArrow exists: " .. tostring(type(HaloTextHelper.addTextWithArrow) == "function"))
    end
    
    print("=== End Diagnostic ===")
    return true
end

-- Add function to check buff status
function BetterRestingTest.checkBuff()
    local player = getPlayer()
    if not player then
        print("No player found!")
        return
    end
    
    if BetterResting and BetterResting.ClientBuffData then
        if BetterResting.ClientBuffData.chairBuffActive then
            local currentHours = BetterResting.getCurrentGameHours()
            local endTime = BetterResting.ClientBuffData.chairBuffEndTime
            local remaining = endTime - currentHours
            local remainingMinutes = math.floor(remaining * 60)
            
            local message = "Well Rested buff active! " .. remainingMinutes .. " min remaining"
            HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
            print("Buff Status: ACTIVE - " .. remainingMinutes .. " minutes remaining")
        else
            HaloTextHelper.addTextWithArrow(player, "Well Rested buff: INACTIVE", true, 255, 100, 0)
            print("Buff Status: INACTIVE")
        end
    else
        print("Buff data not available")
    end
end

-- Initialize on game start (like the working mod does)
Events.OnGameStart.Add(initBetterResting)
Events.OnGameStart.Add(initBetterResting)