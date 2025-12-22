-- BetterResting Server-side Script
-- Handles game mechanics (stamina, healing, buffs) - authoritative in multiplayer
-- In single-player, this runs alongside client script

print("=========================================")
print("[BetterResting SERVER] Script file is being loaded!")
print("=========================================")

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    print("[BetterResting SERVER] BetterResting namespace not found, requiring shared script...")
    require "BetterRestingShared"
    print("[BetterResting SERVER] Shared script required")
else
    print("[BetterResting SERVER] BetterResting namespace already exists")
end

print("[BetterResting SERVER] Script initialization complete")

-- Track player states (game mechanics) - server authoritative
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

-- Track last heal time for each body part (for gradual healing)
local bodyPartHealCooldowns = {}

-- Apply chair buff when stamina is full
local function applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end
    
    -- Build 42 API: Use stats:get(CharacterStat.ENDURANCE)
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    -- Check if stamina just reached full
    if stamina >= 0.99 and not data.wasFullStamina then
        local currentGameHours = BetterResting.getCurrentGameHours()
        local restDurationHours = currentGameHours - data.chairRestStartTime

        if restDurationHours >= BetterResting.Config.MinChairRestTime then
            local BuffDurationHours = math.min(
                BetterResting.Config.MaxBuffDuration,
                math.max(
                    BetterResting.Config.MinBuffDuration,
                    restDurationHours
                )
            )

            data.chairBuffActive = true
            data.chairBuffEndTime = currentGameHours + BuffDurationHours
            
            -- Store buff end time in shared global for client access
            if not BetterResting.ClientBuffData then
                BetterResting.ClientBuffData = {}
            end
            BetterResting.ClientBuffData.chairBuffEndTime = data.chairBuffEndTime
            BetterResting.ClientBuffData.chairBuffActive = true

            data.chairRestStartTime = 0
        end
        data.wasFullStamina = true
    end
    if stamina < 0.99 then 
        data.wasFullStamina = false
    end 
end

-- Process chair/sofa resting bonuses
local function processChairResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    -- Build 42 API: Use stats:get(CharacterStat.ENDURANCE)
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    -- Enhanced stamina regen while resting on chair
    if stamina < 1.0 then
        local baseRegen = 0.001 -- Base stamina regen per tick
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        -- Build 42 API: Use stats:set(CharacterStat.ENDURANCE, value)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
    
    -- Check and apply buff when stamina is full
    applyChairBuff(player, data)
end

-- Process vehicle resting bonuses
local function processVehicleResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    -- Build 42 API: Use stats:get(CharacterStat.ENDURANCE)
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    -- Enhanced stamina regen while in vehicle
    if stamina < 1.0 then
        local baseRegen = 0.001 -- Base stamina regen per tick
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        -- Build 42 API: Use stats:set(CharacterStat.ENDURANCE, value)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

-- Track previous values to detect unexpected changes
local previousValues = {}

-- Process bed resting bonuses
local function processBedResting(player, data, updateCounter)
    print(string.format("[BetterResting SERVER] processBedResting called (tick %d)", updateCounter))
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then 
        print("[BetterResting SERVER] WARNING: bodyDamage is nil!")
        return 
    end
    
    local playerKey = tostring(player:getPlayerNum())
    print(string.format("[BetterResting SERVER] Processing bed resting for player %s", playerKey))
    
    -- Enhanced stamina regen while in bed
    local stats = player:getStats()
    if stats then
        -- Build 42 API: Use stats:get(CharacterStat.ENDURANCE)
        local stamina = stats:get(CharacterStat.ENDURANCE)
        if stamina and stamina < 1.0 then
            local baseRegen = 0.001 -- Base stamina regen per tick
            local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
            local newStamina = math.min(1.0, stamina + bonusRegen)
            
            -- Build 42 API: Use stats:set(CharacterStat.ENDURANCE, value)
            stats:set(CharacterStat.ENDURANCE, newStamina)
        end
    end
    
    -- Enhanced HP regen
    local health = bodyDamage:getHealth() / 100.0  -- Returns 0-100, convert to 0-1
    if health and health < 1.0 then
        local healedAny = false
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            -- Gradual healing: reduce wound times incrementally
            local woundHealCooldown = 6  -- Heal wounds every 6 ticks instead of every tick
            
            for i = 1, bodyParts:size() do
                local part = bodyParts:get(i - 1)
                if part then
                    local partHealth = part:getHealth()
                    if partHealth and partHealth < 100.0 then
                        local partKey = tostring(player:getPlayerNum()) .. "_" .. tostring(i)
                        local lastWoundHeal = bodyPartHealCooldowns[partKey .. "_wound"] or 0
                        local partHealed = false
                        
                        -- Only heal wounds every N ticks to slow down healing
                        if updateCounter - lastWoundHeal >= woundHealCooldown then
                            -- Gradually reduce wound times
                            -- Reduce scratch time
                            if part.getScratchTime and part.setScratchTime and part.setScratched then
                                local scratchTime = part:getScratchTime()
                                if scratchTime and scratchTime > 0 then
                                    local oldTime = scratchTime
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, scratchTime - reduction)
                                    
                                    if updateCounter % 60 == 0 then -- Log every second
                                        print(string.format("[BetterResting SERVER] Part %d: Scratch time %.4f -> %.4f", 
                                            i, oldTime, newTime))
                                    end
                                    
                                    if newTime <= 0 then
                                        part:setScratched(false, true)
                                        print(string.format("[BetterResting SERVER] Part %d: Scratch removed", i))
                                    else
                                        part:setScratchTime(newTime)
                                        -- Verify
                                        local verifyTime = part:getScratchTime()
                                        if math.abs(verifyTime - newTime) > 0.0001 then
                                            print(string.format("[BetterResting SERVER] WARNING: Scratch time mismatch! Set %.4f but got %.4f", 
                                                newTime, verifyTime))
                                        end
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce cut time
                            if part.getCutTime and part.setCutTime and part.setCut then
                                local cutTime = part:getCutTime()
                                if cutTime and cutTime > 0 then
                                    local oldTime = cutTime
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, cutTime - reduction)
                                    
                                    if updateCounter % 60 == 0 then -- Log every second
                                        print(string.format("[BetterResting SERVER] Part %d: Cut time %.4f -> %.4f", 
                                            i, oldTime, newTime))
                                    end
                                    
                                    if newTime <= 0 then
                                        part:setCut(false)
                                        print(string.format("[BetterResting SERVER] Part %d: Cut removed", i))
                                    else
                                        part:setCutTime(newTime)
                                        -- Verify
                                        local verifyTime = part:getCutTime()
                                        if math.abs(verifyTime - newTime) > 0.0001 then
                                            print(string.format("[BetterResting SERVER] WARNING: Cut time mismatch! Set %.4f but got %.4f", 
                                                newTime, verifyTime))
                                        end
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce deep wound time
                            if part.getDeepWoundTime and part.setDeepWoundTime and part.setDeepWounded then
                                local deepWoundTime = part:getDeepWoundTime()
                                if deepWoundTime and deepWoundTime > 0 then
                                    local oldTime = deepWoundTime
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, deepWoundTime - reduction)
                                    
                                    if updateCounter % 60 == 0 then -- Log every second
                                        print(string.format("[BetterResting SERVER] Part %d: Deep wound time %.4f -> %.4f", 
                                            i, oldTime, newTime))
                                    end
                                    
                                    part:setDeepWoundTime(newTime)
                                    if newTime <= 0 then
                                        part:setDeepWounded(false)
                                        print(string.format("[BetterResting SERVER] Part %d: Deep wound removed", i))
                                    end
                                    -- Verify
                                    local verifyTime = part:getDeepWoundTime()
                                    if verifyTime and math.abs(verifyTime - newTime) > 0.0001 then
                                        print(string.format("[BetterResting SERVER] WARNING: Deep wound time mismatch! Set %.4f but got %.4f", 
                                            newTime, verifyTime))
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce bleeding time
                            if part.getBleedingTime and part.setBleedingTime then
                                local bleedingTime = part:getBleedingTime()
                                if bleedingTime and bleedingTime > 0 then
                                    local oldTime = bleedingTime
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, bleedingTime - reduction)
                                    
                                    if updateCounter % 60 == 0 then -- Log every second
                                        print(string.format("[BetterResting SERVER] Part %d: Bleeding time %.4f -> %.4f", 
                                            i, oldTime, newTime))
                                    end
                                    
                                    part:setBleedingTime(newTime)
                                    -- Verify
                                    local verifyTime = part:getBleedingTime()
                                    if verifyTime and math.abs(verifyTime - newTime) > 0.0001 then
                                        print(string.format("[BetterResting SERVER] WARNING: Bleeding time mismatch! Set %.4f but got %.4f", 
                                            newTime, verifyTime))
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce muscle strain (stiffness)
                            if part.getStiffness and part.setStiffness then
                                local stiffness = part:getStiffness()
                                if stiffness and stiffness > 0 then
                                    local oldStiffness = stiffness
                                    local partKey = playerKey .. "_part" .. i .. "_stiffness"
                                    local previousStiffness = previousValues[partKey]
                                    
                                    -- Check if value was unexpectedly changed by something else
                                    if previousStiffness and math.abs(stiffness - previousStiffness) > 0.5 then
                                        print(string.format("[BetterResting SERVER] WARNING: Stiffness changed unexpectedly! Expected ~%.2f but got %.2f (diff: %.2f)", 
                                            previousStiffness, stiffness, stiffness - previousStiffness))
                                    end
                                    
                                    local reduction = 0.005 * BetterResting.Config.BedMuscleFatigueReduction * 100
                                    local newStiffness = math.max(0, stiffness - reduction)
                                    
                                    -- Log EVERY time we modify stiffness (for debugging)
                                    print(string.format("[BetterResting SERVER] Part %d: Stiffness %.2f -> %.2f (reduction: %.4f, tick %d)", 
                                        i, oldStiffness, newStiffness, reduction, updateCounter))
                                    
                                    part:setStiffness(newStiffness)
                                    
                                    -- Verify it was set correctly
                                    local verifyStiffness = part:getStiffness()
                                    if math.abs(verifyStiffness - newStiffness) > 0.01 then
                                        print(string.format("[BetterResting SERVER] WARNING: Stiffness mismatch! Set %.2f but got %.2f", 
                                            newStiffness, verifyStiffness))
                                    end
                                    
                                    -- Store for next check
                                    previousValues[partKey] = newStiffness
                                    
                                    -- If stiffness reaches 0, remove it from fitness system
                                    if newStiffness <= 0 and player.getFitness then
                                        local fitness = player:getFitness()
                                        if fitness and fitness.removeStiffnessValue then
                                            fitness:removeStiffnessValue(BodyPartType.ToString(part:getType()))
                                        end
                                    end
                                    
                                    partHealed = true
                                end
                            end
                            
                            if partHealed then
                                bodyPartHealCooldowns[partKey .. "_wound"] = updateCounter
                            end
                        end
                        
                        -- Gradually restore health
                        if part.RestoreToFullHealth and partHealth < 70.0 then
                            local lastHeal = bodyPartHealCooldowns[partKey] or 0
                            local healCooldown = math.max(1, math.floor(600 / BetterResting.Config.BedHPRegenMultiplier))
                            
                            if updateCounter - lastHeal >= healCooldown then
                                part:RestoreToFullHealth()
                                bodyPartHealCooldowns[partKey] = updateCounter
                                healedAny = true
                            end
                        elseif partHealed then
                            healedAny = true
                        end
                    end
                end
            end
        end
    end
    
    -- Reduce muscle fatigue faster
    local parts = bodyDamage:getBodyParts()
    if parts then
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            if part then
                if part.getPain and part.setPain then
                    local pain = part:getPain()
                    if pain and pain > 0 then
                        local reduction = pain * BetterResting.Config.BedMuscleFatigueReduction * 0.01
                        local newPain = math.max(0, pain - reduction)
                        part:setPain(newPain)
                    end
                end
            end
        end
    end
end

-- Main server update loop - handles game mechanics
-- DISABLED: All game mechanics moved to shared script (BetterRestingShared.lua)
-- This script is kept for reference but no longer processes game mechanics
local updateCounter = 0
print("[BetterResting SERVER] Server script loaded (game mechanics disabled - using shared script instead)")

-- DISABLED: Game mechanics now handled in shared script
--[[
Events.OnPlayerUpdate.Add(function(player)
    if not player then 
        print("[BetterResting SERVER] WARNING: OnPlayerUpdate called with nil player!")
        return 
    end
    
    -- In Build 42, server scripts in server/ directory should only load on server
    -- But let's log to confirm
    if updateCounter == 0 then
        local serverCheck = "unknown"
        if isServer then
            serverCheck = tostring(isServer())
        elseif isClient then
            serverCheck = "not client (probably server)"
        end
        print(string.format("[BetterResting SERVER] OnPlayerUpdate first call - isServer check: %s", serverCheck))
    end
    
    -- Server script runs on server (in multiplayer) and in single-player (where client = server)
    updateCounter = updateCounter + 1
    
    -- Log first few updates to confirm it's running
    if updateCounter <= 10 then
        local serverCheck = "unknown"
        if isServer then
            serverCheck = tostring(isServer())
        elseif isClient then
            serverCheck = "not client"
        end
        print(string.format("[BetterResting SERVER] OnPlayerUpdate tick %d for player %s (server check: %s)", 
            updateCounter, player:getUsername() or "unknown", serverCheck))
    end
    
    -- Initialize player data
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

    -- Log rest type detection (aggressive logging for debugging)
    if updateCounter <= 20 or restType == BetterResting.RestType.BED or data.lastRestType ~= restType then
        print(string.format("[BetterResting SERVER] Player %s: restType=%s, lastRestType=%s (tick %d)", 
            player:getUsername() or "unknown", restType or "nil", data.lastRestType or "nil", updateCounter))
    end

    -- Track rest type changes
    if data.lastRestType ~= restType then
        print(string.format("[BetterResting SERVER] Rest type changed: %s -> %s", 
            data.lastRestType or "nil", restType or "nil"))
        if restType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = BetterResting.getCurrentGameHours()
        elseif data.lastRestType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = 0
            data.wasFullStamina = false
        end
    end
    
    data.lastRestType = restType
    data.currentRestType = restType
    
    -- Process bonuses based on rest type (GAME MECHANICS - SERVER AUTHORITATIVE)
    if restType == BetterResting.RestType.CHAIR then
        if updateCounter % 60 == 0 then
            print(string.format("[BetterResting SERVER] Processing CHAIR resting (tick %d)", updateCounter))
        end
        processChairResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.VEHICLE then
        if updateCounter % 60 == 0 then
            print(string.format("[BetterResting SERVER] Processing VEHICLE resting (tick %d)", updateCounter))
        end
        processVehicleResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.BED then
        -- Log EVERY tick when in bed for debugging
        print(string.format("[BetterResting SERVER] Processing BED resting for player %s (tick %d)", 
            player:getUsername() or "unknown", updateCounter))
        processBedResting(player, data, updateCounter)
    elseif updateCounter % 300 == 0 then -- Log every 5 seconds when not resting
        print(string.format("[BetterResting SERVER] Player %s rest type: %s (tick %d)", 
            player:getUsername() or "unknown", restType or "none", updateCounter))
    end
    
    -- Clean up buffs when expired
    if data.chairBuffActive then
        local currentHours = BetterResting.getCurrentGameHours()
        if currentHours >= data.chairBuffEndTime then
            data.chairBuffActive = false
            if BetterResting.ClientBuffData then
                BetterResting.ClientBuffData.chairBuffActive = false
                BetterResting.ClientBuffData.chairBuffEndTime = 0
            end
        end
    end
end)
--]]

-- Force print to console immediately
print("=========================================")
print("[BetterResting SERVER] Server script loaded and initialized")
print("=========================================")

-- Also try writeLog if available
if writeLog then
    writeLog("BetterResting", "Server script loaded")
end

-- Try multiple ways to verify script is running
print("[BetterResting SERVER] Setting up event handlers...")

-- Verify server script is running
Events.OnGameStart.Add(function()
    print("=========================================")
    print("[BetterResting SERVER] OnGameStart event - Server script confirmed active")
    print("[BetterResting SERVER] isServer() = " .. tostring(isServer()))
    print("[BetterResting SERVER] isClient() = " .. tostring(isClient()))
    print("=========================================")
end)

-- Test with a simple event that should fire
Events.OnInitGlobalModData.Add(function()
    print("[BetterResting SERVER] OnInitGlobalModData - Server script is active!")
end)

-- Add periodic status check
Events.EveryTenMinutes.Add(function()
    print("[BetterResting SERVER] Server script is running (10 minute check)")
end)

-- Test immediate execution
print("[BetterResting SERVER] All event handlers registered")
print("[BetterResting SERVER] Script file execution complete")

