-- BetterResting Server-side Script
-- All game mechanics run here

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    require "BetterRestingShared"
end

-- Track player states
local playerRestData = {}

-- Initialize player data tracking
local function initPlayerData(player)
    local playerNum = player:getPlayerNum()
    if not playerRestData[playerNum] then
        playerRestData[playerNum] = {
            currentRestType = nil,
            chairBuffActive = false,
            chairBuffEndTime = 0,
            lastStaminaLevel = 1.0,
            wasFullStamina = false,
            chairRestStartTime = 0,
            lastRestType = nil,
        }
    end
    return playerRestData[playerNum]
end

-- Functions moved to shared script

-- Apply chair buff when stamina is full
local function applyChairBuff(player, data)
    local stats = player:getStats()
    local stamina = stats:getEndurance()
    
    -- Check if stamina just reached full
    if stamina >= 0.99 and not data.wasFullStamina then
        print("BetterResting [SERVER] Stamina reached full! Stamina: " .. stamina)
        local currentGameHours = BetterResting.getCurrentGameHours()
        local restDurationHours = currentGameHours - data.chairRestStartTime
        print("BetterResting [SERVER] Rest duration: " .. restDurationHours .. " hours, Start time: " .. data.chairRestStartTime .. ", Current: " .. currentGameHours)

        if restDurationHours >= BetterResting.Config.MinChairRestTime then
            print("BetterResting [SERVER] Minimum rest time met! Activating buff...")
            local BuffDurationHours = math.min(
                BetterResting.Config.MaxBuffDuration,
                math.max(
                    BetterResting.Config.MinBuffDuration,
                    restDurationHours
                )
            )

            data.chairBuffActive = true
            data.chairBuffEndTime = currentGameHours + BuffDurationHours
            print("BetterResting [SERVER] Buff activated! Duration: " .. BuffDurationHours .. " hours, End time: " .. data.chairBuffEndTime)

            -- Send buff activation message to client
            local buffMinutes = math.floor(BuffDurationHours * 60)
            local buffEndTime = currentGameHours + BuffDurationHours
            
            -- Store buff end time in shared global for client access (works in both SP and MP)
            if not BetterResting.ClientBuffData then
                BetterResting.ClientBuffData = {}
            end
            BetterResting.ClientBuffData.chairBuffEndTime = buffEndTime
            BetterResting.ClientBuffData.chairBuffActive = true
            print("BetterResting [SERVER] Stored in ClientBuffData - Active: " .. tostring(BetterResting.ClientBuffData.chairBuffActive) .. ", End time: " .. buffEndTime)
            
            -- Send message to client
            print("BetterResting [SERVER] isClient(): " .. tostring(isClient()))
            if isClient() then
                print("BetterResting [SERVER] Sending client command ShowBuffMessage")
                sendClientCommand(player, "BetterResting", "ShowBuffMessage", {
                    buff = "chair",
                    duration = buffMinutes,
                    buffEndTime = buffEndTime
                })
            else
                print("BetterResting [SERVER] Single player mode - client will check shared data")
            end

            data.chairRestStartTime = 0
        else
            print("BetterResting [SERVER] Rest duration too short: " .. restDurationHours .. " < " .. BetterResting.Config.MinChairRestTime)
        end
        data.wasFullStamina = true
    end
    if stamina < 0.99 then data.wasFullStamina = false
    end 
end

-- Process chair/sofa resting bonuses
local function processChairResting(player, data)
    local stats = player:getStats()
    local stamina = stats:getEndurance()
    
    -- Enhanced stamina regen while resting on chair
    if stamina < 1.0 then
        local baseRegen = 0.001 -- Base stamina regen per tick (adjust as needed)
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        stats:setEndurance(math.min(1.0, stamina + bonusRegen))
    end
    
    -- Check and apply buff when stamina is full
    applyChairBuff(player, data)
    
    -- Apply stamina consumption reduction if buff is active
    -- (This is handled during stamina consumption events)
end

-- Process vehicle resting bonuses
local function processVehicleResting(player, data)
    local stats = player:getStats()
    local stamina = stats:getEndurance()
    
    -- Enhanced stamina regen while in vehicle
    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        stats:setEndurance(math.min(1.0, stamina + bonusRegen))
    end
    
    -- Vehicle endurance buff is always active while in vehicle
    -- (Consumption reduction handled during stamina use)
end

-- Process bed resting bonuses
local function processBedResting(player, data)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    
    -- Enhanced HP regen
    -- Project Zomboid's HP regen is slow, we'll give it a small boost
    local health = player:getHealth()
    if health < 1.0 then
        -- Small HP regen boost (very slow in vanilla, so small boost here)
        -- Note: Actual HP regen might need different approach depending on game version
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            if part then
                local damage = part:getDamage()
                if damage > 0 then
                    -- Reduce damage slightly (healing)
                    local healAmount = 0.00001 * BetterResting.Config.BedHPRegenMultiplier
                    part:setDamage(math.max(0, damage - healAmount))
                end
            end
        end
    end
    
    -- Reduce muscle fatigue faster
    -- Muscle fatigue is stored in body parts
    local parts = bodyDamage:getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part then
            -- Check if part has muscle fatigue (pain > 0 from exercise)
            local pain = part:getPain()
            if pain > 0 then
                -- Reduce pain faster (muscle fatigue)
                local reduction = pain * BetterResting.Config.BedMuscleFatigueReduction * 0.01
                part:setPain(math.max(0, pain - reduction))
            end
        end
    end
end

-- Hook stamina consumption to apply reduction buffs
local function onStaminaConsumption(player, amount)
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)
    local reduction = 0
    
    -- Apply consumption reduction based on rest type and buffs
    if restType == BetterResting.RestType.VEHICLE then
        reduction = amount * (1.0 - BetterResting.Config.VehicleStaminaConsumptionReduction)
    elseif data.chairBuffActive and restType == BetterResting.RestType.CHAIR then
        reduction = amount * (1.0 - BetterResting.Config.ChairStaminaConsumptionReduction)
    end
    
    if reduction > 0 then
        -- Return the reduced amount (negative because we're reducing consumption)
        return -reduction
    end
    
    return 0
end

-- Main update loop - runs every game tick
Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

    if data.lastRestType ~= restType then
        print("BetterResting [SERVER] Rest type changed from " .. tostring(data.lastRestType) .. " to " .. tostring(restType))
        
        if restType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = BetterResting.getCurrentGameHours()
            print("BetterResting [SERVER] Started resting on chair at: " .. data.chairRestStartTime .. " game hours")
        
        elseif data.lastRestType == BetterResting.RestType.CHAIR then 
            print("BetterResting [SERVER] Stopped resting on chair")
            data.chairRestStartTime = 0
            data.wasFullStamina = false
        end
    end
    
    data.lastRestType = restType
    data.currentRestType = restType
    
    
    -- Process bonuses based on rest type
    if restType == BetterResting.RestType.CHAIR then
        processChairResting(player, data)
    elseif restType == BetterResting.RestType.VEHICLE then
        processVehicleResting(player, data)
    elseif restType == BetterResting.RestType.BED then
        processBedResting(player, data)
    end
    
    -- Clean up buffs and notify client when expired
    if data.chairBuffActive then
        local currentHours = BetterResting.getCurrentGameHours()
        if currentHours >= data.chairBuffEndTime then
            data.chairBuffActive = false
            -- Update shared data for client
            if BetterResting.ClientBuffData then
                BetterResting.ClientBuffData.chairBuffActive = false
                BetterResting.ClientBuffData.chairBuffEndTime = 0
            end
            -- Notify client that buff expired
            if isClient() then
                sendClientCommand(player, "BetterResting", "BuffExpired", {
                    buff = "chair"
                })
            end
        end
    end
end)

-- Hook into stamina usage (if available in API)
-- Note: This might need adjustment based on actual Build 42.13 API
Events.OnPlayerMove.Add(function(player, dx, dy)
    if not player then return end
    
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)
    
    -- Apply stamina consumption reduction
    -- This is a simplified approach - actual implementation may vary
end)

print("BetterResting server script loaded")
if writeLog then
    writeLog("BetterResting", "Server script loaded")
end

-- Verify server script loaded with event
Events.OnGameStart.Add(function()
    print("BetterResting [SERVER] OnGameStart - Server script confirmed loaded!")
    print("BetterResting [SERVER] Config - MinRestTime: " .. tostring(BetterResting.Config.MinChairRestTime) .. ", MinBuff: " .. tostring(BetterResting.Config.MinBuffDuration) .. ", MaxBuff: " .. tostring(BetterResting.Config.MaxBuffDuration))
end)