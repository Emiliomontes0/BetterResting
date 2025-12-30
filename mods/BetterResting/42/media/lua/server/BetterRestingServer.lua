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

-- Track expected stiffness values per body part to prevent client overwrites
-- Key: "playerNum_partIndex" -> expected stiffness value
local expectedStiffness = {}

-- Track expected pain values per body part to prevent stiffness regeneration
-- Key: "playerNum_partIndex" -> expected pain value
local expectedPain = {}

-- Track expected character-level pain to prevent it from being recalculated from body parts
-- Key: "playerNum" -> expected character-level pain value
local expectedCharacterPain = {}

local function applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
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

function processBedRestingStiffness(player, updateCounter)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then 
        print("[BetterResting SERVER] WARNING: bodyDamage is nil!")
        return
    end
    
    -- Create stiffness action object using new class-based approach
    local stiffnessAction = BedStiffnessAction:new(player, updateCounter)
    
    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts then
        for i = 1, bodyParts:size() do
            local part = bodyParts:get(i-1)
            if part then
                -- Process stiffness using the class method
                stiffnessAction:processStiffness(part, i, expectedStiffness)
            end
        end
        
        -- Sync body damage changes using the class method
        stiffnessAction:syncBodyDamage(bodyDamage)
    end
end

-- Continuously enforce expected stiffness and pain values to prevent game engine from resetting them
-- This runs on every update, regardless of rest type, to maintain reduced values
local function enforceExpectedStiffness(player)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    
    local playerNum = player:getPlayerNum()
    local playerKey = tostring(playerNum)
    local bodyParts = bodyDamage:getBodyParts()
    
    if not bodyParts then return end
    
    local bodyPartsModified = false
    
    -- Enforce expected character-level pain (more aggressively to prevent recalculation from body parts)
    local stats = player:getStats()
    if stats and CharacterStat and CharacterStat.PAIN then
        local painKey = playerKey .. "_characterPain"
        local expectedCharPain = expectedCharacterPain[painKey]
        
        if expectedCharPain then
            local currentCharPain = stats:get(CharacterStat.PAIN)
            
            -- If expected value is 0 or negative, clear it
            if expectedCharPain <= 0 then
                expectedCharacterPain[painKey] = nil
            -- If current pain is higher than expected (even slightly), enforce expected value aggressively
            -- This prevents game engine from recalculating pain from body parts
            elseif currentCharPain > expectedCharPain + 0.001 then
                stats:set(CharacterStat.PAIN, expectedCharPain)
                bodyPartsModified = true
            -- If current pain is lower than expected (natural decrease), update expected to match
            elseif currentCharPain < expectedCharPain - 0.01 then
                expectedCharacterPain[painKey] = currentCharPain
            end
        end
    end
    
    for i = 1, bodyParts:size() do
        local part = bodyParts:get(i-1)
        if part then
            local partKey = playerKey .. "_" .. i
            
            -- Enforce expected stiffness
            if part.getStiffness and part.setStiffness then
                local expectedValue = expectedStiffness[partKey]
                
                if expectedValue then
                    local currentStiffness = part:getStiffness()
                    
                    -- If expected value is 0 or negative, clear it
                    if expectedValue <= 0 then
                        expectedStiffness[partKey] = nil
                    -- If current stiffness is significantly higher than expected, enforce expected value
                    -- This prevents game engine/client from resetting our reduced values
                    elseif currentStiffness > expectedValue + 0.01 then
                        part:setStiffness(expectedValue)
                        bodyPartsModified = true
                    -- If current stiffness is lower than expected (natural decrease), update expected to match
                    -- This allows natural recovery while still preventing resets
                    elseif currentStiffness < expectedValue - 0.01 then
                        expectedStiffness[partKey] = currentStiffness
                    end
                end
            end
            
            -- Enforce expected pain (pain can cause stiffness to regenerate)
            if part.getPain and part.setPain then
                local expectedPainValue = expectedPain[partKey]
                
                if expectedPainValue then
                    local currentPain = part:getPain()
                    
                    -- If expected value is 0 or negative, clear it
                    if expectedPainValue <= 0 then
                        expectedPain[partKey] = nil
                    -- If current pain is significantly higher than expected, enforce expected value
                    elseif currentPain > expectedPainValue + 0.01 then
                        part:setPain(expectedPainValue)
                        bodyPartsModified = true
                    -- If current pain is lower than expected (natural decrease), update expected to match
                    elseif currentPain < expectedPainValue - 0.01 then
                        expectedPain[partKey] = currentPain
                    end
                end
            end
        end
    end
    
    -- Sync if we made changes
    if bodyPartsModified and isServer() then
        if bodyDamage.sync then
            bodyDamage:sync()
        end
        if player.transmitBodyDamage then
            player:transmitBodyDamage()
        end
    end
end

-- Main server update loop - handles game mechanics
-- Server-side authoritative execution ensures changes persist and sync properly
local updateCounter = 0
print("[BetterResting SERVER] Server script loaded - Game mechanics ENABLED on server side")

-- Server-side authoritative game mechanics handler
Events.OnPlayerUpdate.Add(function(player)
    if not player then 
        print("[BetterResting SERVER] WARNING: OnPlayerUpdate called with nil player!")
        return 
    end
    
    -- Verify we're on server side (scripts in server/ directory should only load on server in multiplayer)
    -- In single-player, this still runs as the server
    if updateCounter == 0 then
        local serverCheck = "unknown"
        if isServer and type(isServer) == "function" then
            serverCheck = tostring(isServer())
        elseif isClient and type(isClient) == "function" then
            serverCheck = "not client (server)"
        end
        print(string.format("[BetterResting SERVER] OnPlayerUpdate first call - Server authoritative mode active (check: %s)", serverCheck))
    end
    
    -- Server-side authoritative execution - changes made here persist and sync to clients
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

    -- Aggressive logging for debugging - log rest type every tick for first 10 ticks, then when it changes
    if updateCounter <= 10 or restType ~= data.lastRestType then
        print(string.format("[BetterResting SERVER] Player %s: restType=%s, lastRestType=%s (tick %d)", 
            player:getUsername() or "unknown", tostring(restType), tostring(data.lastRestType), updateCounter))
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
        processBedRestingStiffness(player, updateCounter)
    elseif updateCounter % 300 == 0 then -- Log every 5 seconds when not resting
        print(string.format("[BetterResting SERVER] Player %s rest type: %s", 
            player:getUsername() or "unknown", restType or "none"))
    end
    
    -- CRITICAL: Always enforce expected stiffness values to prevent game engine from resetting them
    -- This ensures reduced stiffness from bed resting persists even after getting up
    enforceExpectedStiffness(player)
    
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

-- Force print to console immediately
print("=========================================")
print("[BetterResting SERVER] Server script loaded and initialized")
print("[BetterResting SERVER] GAME MECHANICS ACTIVE - Server authoritative mode")
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

--public double getFatiqueMultiplier()