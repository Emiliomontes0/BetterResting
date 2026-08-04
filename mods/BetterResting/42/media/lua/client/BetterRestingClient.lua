if not BetterResting then
    require "BetterRestingShared"
end

local lastRestType = nil

local clientBuffData = {
    chairBuffActive = false,
    lastIndicatorTime = 0,
    indicatorInterval = 30,
}

local hasShownInitialMessage = false

local function applySyncedBuffState(active, endTime)
    BetterResting.ClientBuffData = BetterResting.ClientBuffData or {}
    BetterResting.ClientBuffData.chairBuffActive = active and true or false
    BetterResting.ClientBuffData.chairBuffEndTime = endTime or 0
end

local function showBuffMessage(buffType, duration, buffEndTime)
    if buffType == "chair" then
        local player = getPlayer()
        if player and BetterResting.Config.ShowMessages then
            local durationText = ""
            if duration then
                durationText = " (" .. duration .. " minutes)"
            end
            local message = "Well Rested! Reduced stamina consumption" .. durationText
            HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
            clientBuffData.chairBuffActive = true
            clientBuffData.lastIndicatorTime = 0
        end
    end
end

local function showBuffExpired(buffType)
    if buffType == "chair" then
        local player = getPlayer()
        if player and BetterResting.Config.ShowMessages then
            HaloTextHelper.addTextWithArrow(player, "Rested feeling fades...", true, 255, 0, 0)
            clientBuffData.chairBuffActive = false
        end
    end
end

local restMessageData = {
    startTick = 0,
    message = nil,
    duration = 600,
    refreshInterval = 60,
    lastRefresh = 0
}

local updateCounter = 0

local function isLocalPlayer(player)
    if not player then
        return false
    end
    if player.isLocalPlayer then
        return player:isLocalPlayer()
    end
    local localPlayer = getPlayer()
    return localPlayer ~= nil and player == localPlayer
end

-- B42: sendClientCommand(module, command, args) — do NOT pass player as first arg
local function sendRestCommand(command)
    sendClientCommand("BetterResting", command, {})
end

-- MP: client detects rest (APIs work locally), server applies bonuses + syncPlayerStats
local function requestServerRestProcessing(player, restType)
    if not isClient() or not player or not isLocalPlayer(player) then
        return
    end
    if restType == BetterResting.RestType.CHAIR then
        sendRestCommand("ProcessChairResting")
    elseif restType == BetterResting.RestType.VEHICLE then
        sendRestCommand("ProcessVehicleResting")
    elseif restType == BetterResting.RestType.BED then
        sendRestCommand("ProcessBedResting")
        sendRestCommand("ReduceStiffness")
        sendRestCommand("HealWounds")
    end
end

Events.OnPlayerUpdate.Add(function(player)
    if not player then return end

    updateCounter = updateCounter + 1

    local restType = BetterResting.detectRestType(player)
    requestServerRestProcessing(player, restType)

    if not BetterResting.ClientBuffData then
        BetterResting.ClientBuffData = {}
    end

    local serverBuffActive = BetterResting.ClientBuffData.chairBuffActive or false
    local serverBuffEndTime = BetterResting.ClientBuffData.chairBuffEndTime or 0
    local wasBuffActive = clientBuffData.chairBuffActive

    if serverBuffActive then
        local calendar = Calendar.getInstance()
        local currentTimeMinutes = 0
        if calendar then
            currentTimeMinutes = calendar:getTimeInMillis() / (1000 * 60)
        else
            currentTimeMinutes = BetterResting.getCurrentGameHours() * 60
        end

        local endTime = serverBuffEndTime

        if not wasBuffActive and endTime > 0 then
            if endTime > currentTimeMinutes then
                local remaining = endTime - currentTimeMinutes
                local remainingMinutes = math.floor(remaining)
                showBuffMessage("chair", remainingMinutes, endTime)
            end
        end

        if wasBuffActive and endTime > 0 and currentTimeMinutes >= endTime then
            showBuffExpired("chair")
        end

        clientBuffData.chairBuffActive = serverBuffActive
    elseif wasBuffActive then
        showBuffExpired("chair")
        clientBuffData.chairBuffActive = false
    end

    if restType ~= lastRestType and restType ~= BetterResting.RestType.FLOOR then
        if BetterResting.Config.ShowMessages then
            local messages = {
                [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
                [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
                [BetterResting.RestType.BED] = "Resting in bed - Wounds and muscle strain",
            }

            if messages[restType] then
                restMessageData.startTick = updateCounter
                restMessageData.message = messages[restType]
                restMessageData.lastRefresh = updateCounter
                HaloTextHelper.addTextWithArrow(player, messages[restType], true, 0, 100, 255)
            end
        end
    end

    if restType ~= BetterResting.RestType.FLOOR then
        if BetterResting.Config.ShowMessages then
            local messages = {
                [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
                [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
                [BetterResting.RestType.BED] = "Resting in bed - Wounds and muscle strain",
            }

            local currentMessage = messages[restType]
            if currentMessage then
                restMessageData.message = currentMessage

                local elapsed = updateCounter - restMessageData.startTick
                if elapsed < restMessageData.duration then
                    if updateCounter - restMessageData.lastRefresh >= restMessageData.refreshInterval then
                        HaloTextHelper.addTextWithArrow(player, currentMessage, true, 0, 100, 255)
                        restMessageData.lastRefresh = updateCounter
                    end
                else
                    restMessageData.message = nil
                end
            end
        else
            restMessageData.message = nil
        end
    else
        restMessageData.message = nil
    end

    lastRestType = restType

    if clientBuffData.chairBuffActive and BetterResting.Config.ShowMessages then
        local currentTime = Calendar.getInstance():getTimeInMillis() / 1000
        local timeSinceLastIndicator = currentTime - clientBuffData.lastIndicatorTime

        if timeSinceLastIndicator >= clientBuffData.indicatorInterval then
            HaloTextHelper.addTextWithArrow(player, "I feel well rested", true, 0, 255, 0)
            clientBuffData.lastIndicatorTime = currentTime
        end
    end
end)

-- Receive Well Rested buff state from server (MP / listen host)
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "BetterResting" then
        return
    end
    if command == "SyncChairBuff" then
        applySyncedBuffState(args and args.active, args and args.endTime)
    end
end)

if writeLog then
    writeLog("BetterResting", "Client script loaded")
end

local function initBetterResting()
    local player = getPlayer()
    if not player then return end

    if not hasShownInitialMessage and BetterResting.Config.ShowMessages then
        HaloTextHelper.addTextWithArrow(player, "BetterResting Mod Loaded!", true, 0, 255, 0)
        hasShownInitialMessage = true
    end

    -- Ask server for current buff state after join/load (no-op in pure SP authority path)
    if isClient() then
        sendClientCommand("BetterResting", "RequestChairBuffSync", {})
    end
end

BetterRestingTest = {}
function BetterRestingTest.showMessage(msg)
    local player = getPlayer()
    if not player then
        return false
    end
    if not HaloTextHelper then
        return false
    end
    local message = msg or "BetterResting Mod Test Message!"
    HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
    return true
end

function BetterRestingTest.checkMod()
    local player = getPlayer()
    if player and BetterResting then
        BetterResting.detectRestType(player)
    end
    return true
end

function BetterRestingTest.checkBuff()
    local player = getPlayer()
    if not player then
        return
    end

    if BetterResting and BetterResting.ClientBuffData and BetterResting.Config.ShowMessages then
        if BetterResting.ClientBuffData.chairBuffActive then
            local calendar = Calendar.getInstance()
            local currentTimeMinutes = 0
            if calendar then
                currentTimeMinutes = calendar:getTimeInMillis() / (1000 * 60)
            end
            local endTime = BetterResting.ClientBuffData.chairBuffEndTime or 0
            local remainingMinutes = math.floor(endTime - currentTimeMinutes)

            local message = "Well Rested buff active! " .. remainingMinutes .. " min remaining"
            HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
        else
            HaloTextHelper.addTextWithArrow(player, "Well Rested buff: INACTIVE", true, 255, 100, 0)
        end
    end
end

Events.OnGameStart.Add(initBetterResting)
