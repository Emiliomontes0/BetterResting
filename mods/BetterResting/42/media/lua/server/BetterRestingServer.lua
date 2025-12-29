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

local bodyPartHealCooldowns = {}

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

-- Track previous values to detect unexpected changes
local previousValues = {}

-- Process bed resting bonuses
--[[
local function processBedResting(player, data, updateCounter)
    -- print(string.format("[BetterResting SERVER] processBedResting called (tick %d)", updateCounter))
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then 
        print("[BetterResting SERVER] WARNING: bodyDamage is nil!")
        return 
    end
    
    local playerKey = tostring(player:getPlayerNum())
    -- print(string.format("[BetterResting SERVER] Processing bed resting for player %s", playerKey))
    
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
        local bodyPartsModified = false  -- Track if we modified any body parts
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            -- Gradual healing: reduce wound times incrementally
            local woundHealCooldown = 1  -- Heal wounds every 6 ticks instead of every tick
            
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
                                    bodyPartsModified = true
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
                                    bodyPartsModified = true
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
                                    bodyPartsModified = true
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
                                    bodyPartsModified = true
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
                                    
                                    -- Check if value was unexpectedly changed by something else (game engine may modify it)
                                    if previousStiffness and math.abs(stiffness - previousStiffness) > 0.5 then
                                        print(string.format("[BetterResting SERVER] WARNING: Stiffness changed unexpectedly! Expected ~%.2f but got %.2f (diff: %.2f) - Re-applying reduction to current value", 
                                            previousStiffness, stiffness, stiffness - previousStiffness))
                                        -- The game engine/client synced a different value - work with the current server value
                                        -- We'll apply our reduction to whatever the current value is
                                        oldStiffness = stiffness
                                    end
                                    
                                    local reduction = 0.001 * BetterResting.Config.BedMuscleFatigueReduction * 100
                                    local newStiffness = math.max(0, stiffness - reduction)
                                    
                                    -- Only log occasionally to reduce spam (every 60 ticks = ~1 second)
                                    if updateCounter % 60 == 0 then
                                        print(string.format("[BetterResting SERVER] Part %d: Stiffness %.2f -> %.2f (reduction: %.4f, tick %d)", 
                                            i, oldStiffness, newStiffness, reduction, updateCounter))
                                    end
                                    
                                    part:setStiffness(newStiffness)
                                    
                                    bodyPartsModified = true
                                    
                                    -- Verify it was set correctly - but don't fight if game engine changes it
                                    -- We'll work with whatever value is there next tick
                                    local verifyStiffness = part:getStiffness()
                                    if math.abs(verifyStiffness - newStiffness) > 0.01 then
                                        -- Game engine immediately changed it - this is expected in multiplayer
                                        -- We'll work with the actual value next tick
                                        if updateCounter % 60 == 0 then
                                            print(string.format("[BetterResting SERVER] Part %d: Stiffness immediately changed by game engine: Set %.2f but got %.2f (will continue reducing from current value)", 
                                                i, newStiffness, verifyStiffness))
                                        end
                                        previousValues[partKey] = verifyStiffness
                                    else
                                        -- Store the value we successfully set
                                        previousValues[partKey] = newStiffness
                                    end
                                    
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
                                bodyPartsModified = true
                                bodyPartHealCooldowns[partKey] = updateCounter
                                healedAny = true
                            end
                        elseif partHealed then
                            healedAny = true
                        end
                    end
                end
            end
            
            -- CRITICAL: Sync all body damage changes to clients ONCE after all modifications
            -- This prevents client from overwriting our server-side changes with stale data
            if bodyPartsModified and isServer() then
                -- Try multiple sync methods - use whichever is available
                if bodyDamage.sync then
                    bodyDamage:sync()
                elseif player.transmitBodyDamage then
                    player:transmitBodyDamage()
                elseif player.setBodyDamage then
                    -- Force update by re-setting body damage reference
                    player:setBodyDamage(bodyDamage)
                end
            end
        end
    end
    
    -- Sync pain changes if any were made
    if painModified and isServer() then
        if bodyDamage.sync then
            bodyDamage:sync()
        elseif player.transmitBodyDamage then
            player:transmitBodyDamage()
        end
    end
end
--]]

function processBedRestingStiffness(player, updateCounter)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then 
        print("[BetterResting SERVER] WARNING: bodyDamage is nil!")
        return
    end
    local playerNum = player:getPlayerNum()
    local playerKey = tostring(playerNum)

    -- Check and reduce character-level pain (CharacterStat.PAIN) - track and enforce like stiffness
    local stats = player:getStats()
    local characterPain = nil
    if stats and CharacterStat and CharacterStat.PAIN then
        characterPain = stats:get(CharacterStat.PAIN)
        
        if characterPain and characterPain > 0 and stats.set then
            local painKey = playerKey .. "_characterPain"
            local expectedCharPain = expectedCharacterPain[painKey]
            
            -- Calculate pain reduction per tick (same rate as stiffness)
            local painReduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
            local newCharacterPain
            
            -- If we have an expected value, continue reducing from it
            if expectedCharPain then
                newCharacterPain = math.max(0, expectedCharPain - painReduction)
            else
                -- First time seeing this, start from current value
                newCharacterPain = math.max(0, characterPain - painReduction)
            end
            
            -- Update expected value
            expectedCharacterPain[painKey] = newCharacterPain
            
            -- Always enforce the expected value (game engine may recalculate from body parts)
            -- Use tighter tolerance to catch recalculations immediately
            local tolerance = 0.001
            if math.abs(characterPain - newCharacterPain) > tolerance then
                -- Value doesn't match - enforce our expected value
                stats:set(CharacterStat.PAIN, newCharacterPain)
                bodyPartsModified = true
            end
            
            -- Log character-level pain (every 60 ticks = ~1 second)
            if updateCounter and updateCounter % 60 == 0 then
                print(string.format("[BetterResting SERVER] Character-level Pain (CharacterStat.PAIN): %.4f", newCharacterPain))
            end
        else
            -- Pain is 0, clear expected value
            local painKey = playerKey .. "_characterPain"
            expectedCharacterPain[painKey] = nil
        end
    end

    local bodyPartsModified = false
    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts then
        for i = 1, bodyParts:size() do
            local part = bodyParts:get(i-1)
            if part then
                local partKey = playerKey .. "_" .. i
                
                -- Reduce stiffness
                if part.getStiffness and part.setStiffness then
                    local stiffness = part:getStiffness()
                    if stiffness and stiffness > 0 then
                        local expectedValue = expectedStiffness[partKey]
                        
                        -- Calculate reduction per tick (increased for faster recovery)
                        local reduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
                        local newStiffness
                        
                        -- If we have an expected value, continue reducing from it
                        -- This ensures our mod's reduction is enforced even if client overwrites
                        if expectedValue then
                            newStiffness = math.max(0, expectedValue - reduction)
                        else
                            -- First time seeing this part, start from current value
                            newStiffness = math.max(0, stiffness - reduction)
                        end
                        
                        -- Update expected value
                        expectedStiffness[partKey] = newStiffness
                        
                        -- Check if current value matches expected (within tolerance)
                        local tolerance = 0.01
                        if math.abs(stiffness - newStiffness) > tolerance then
                            -- Value doesn't match - enforce our expected value
                            part:setStiffness(newStiffness)
                            bodyPartsModified = true
                        end
                    else
                        -- Stiffness is 0, clear expected value
                        expectedStiffness[partKey] = nil
                    end
                end
                    
                -- Check pain values (pain can cause stiffness to regenerate)
                -- Pain can be accessed via BodyPart.getPain() and BodyPart.getAdditionalPain()
                local partPain = nil
                local partAdditionalPain = nil
                
                if part.getPain then
                    partPain = part:getPain()
                end
                if part.getAdditionalPain then
                    partAdditionalPain = part:getAdditionalPain()
                end
                
                -- Try to reduce pain if methods are available
                -- Note: We may not be able to set pain directly, but we can monitor it
                if partPain and partPain > 0 then
                    local expectedPainValue = expectedPain[partKey]
                    
                    -- Calculate pain reduction per tick (same rate as stiffness)
                    local painReduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
                    local newPain
                    
                    -- If we have an expected value, continue reducing from it
                    if expectedPainValue then
                        newPain = math.max(0, expectedPainValue - painReduction)
                    else
                        -- First time seeing this part, start from current value
                        newPain = math.max(0, partPain - painReduction)
                    end
                    
                    -- Update expected pain value
                    expectedPain[partKey] = newPain
                    
                    -- Try to set pain if method is available
                    -- Note: setPain may not exist, so we track expected values but may not be able to set them
                    if part.setPain then
                        local tolerance = 0.01
                        if math.abs(partPain - newPain) > tolerance then
                            part:setPain(newPain)
                            bodyPartsModified = true
                        end
                    end
                else
                    -- Pain is 0, clear expected value
                    if partPain == 0 or (not partPain) then
                        expectedPain[partKey] = nil
                    end
                end
            end
        end
        
        -- CRITICAL: Sync all body damage changes to clients ONCE after all modifications
        -- This prevents client from overwriting our server-side changes with stale data
        if bodyPartsModified and isServer() then
            -- Primary sync method - sync the entire bodyDamage object
            if bodyDamage.sync then
                bodyDamage:sync()
            end
            
            -- Alternative: Try to force sync through player object
            if player.transmitBodyDamage then
                player:transmitBodyDamage()
            end
        end
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