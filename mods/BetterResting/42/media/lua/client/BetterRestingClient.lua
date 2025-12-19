-- BetterResting Client-side Script
-- Handles UI feedback, messages, and game mechanics
-- (In single-player, client = server, so we handle everything here)

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    require "BetterRestingShared"
end

-- Track player states (game mechanics)
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

-- Track buff states on client (for UI)
local clientBuffData = {
    chairBuffActive = false,
    lastIndicatorTime = 0,
    indicatorInterval = 30, -- Show indicator every 30 seconds while buff is active
}

-- Track if we've shown the initial confirmation message
local hasShownInitialMessage = false
local confirmationTimer = 0

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
            -- Show green text above player (using RGB: 0, 255, 0 for green)
            HaloTextHelper.addTextWithArrow(player, message, true, 0, 255, 0)
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
            HaloTextHelper.addTextWithArrow(player, "Rested feeling fades...", true, 255, 0, 0)
            clientBuffData.chairBuffActive = false
        end
    end
end

-- Note: Removed OnClientCommand handler since we're running everything on client now

-- Show rest location feedback (optional)
local lastRestType = nil

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
            
            -- Show buff message
            local buffMinutes = math.floor(BuffDurationHours * 60)
            showBuffMessage("chair", buffMinutes, data.chairBuffEndTime)
            
            -- Debug output
            print("BetterResting [BUFF] Well Rested buff activated! Duration: " .. buffMinutes .. " minutes")
            print("BetterResting [BUFF] Buff will expire at game hour: " .. data.chairBuffEndTime)

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
        
        -- Debug output every 2 seconds
        if updateCounter and updateCounter % 120 == 0 then
            local staminaPercent = math.floor(stamina * 100)
            local newPercent = math.floor(newStamina * 100)
            print("BetterResting [CHAIR] Stamina: " .. staminaPercent .. "% -> " .. newPercent .. "% (Regen: " .. string.format("%.4f", bonusRegen) .. ")")
        end
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
        
        -- Debug: Show stamina regen every 2 seconds
        if updateCounter and updateCounter % 120 == 0 then
            local staminaPercent = math.floor(stamina * 100)
            local newPercent = math.floor(newStamina * 100)
            print("BetterResting [VEHICLE] Stamina: " .. staminaPercent .. "% -> " .. newPercent .. "% (Regen: " .. string.format("%.4f", bonusRegen) .. ")")
        end
    end
end

-- Track last heal time for each body part (for gradual healing)
local bodyPartHealCooldowns = {}

-- Process bed resting bonuses
local function processBedResting(player, data, updateCounter)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    
    -- Enhanced stamina regen while in bed (TESTING - VERY HIGH)
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
            
            -- Debug: Show stamina regen every 2 seconds
            if updateCounter and updateCounter % 120 == 0 then
                local staminaPercent = math.floor(stamina * 100)
                local newPercent = math.floor(newStamina * 100)
                print("BetterResting [BED] Stamina: " .. staminaPercent .. "% -> " .. newPercent .. "% (Regen: " .. string.format("%.4f", bonusRegen) .. ")")
            end
        end
    end
    
    -- Enhanced HP regen
    -- Build 42 API: Based on ISHealthPanel.lua lines 273-285 and 577
    -- Found: bodyPart:RestoreToFullHealth() and bodyPart:getHealth()
    local health = bodyDamage:getHealth() / 100.0  -- Returns 0-100, convert to 0-1
    if health and health < 1.0 then
        local healedAny = false
        -- Based on ISHealthPanel.lua line 282-285: iterate through body parts
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            -- Debug: Check first body part for available methods
            if updateCounter and updateCounter % 120 == 0 then
                local samplePart = bodyParts:get(0)
                if samplePart then
                    print("BetterResting [BED] Sample part health: " .. tostring(samplePart:getHealth()))
                    print("BetterResting [BED] Has setHealth: " .. tostring(samplePart.setHealth ~= nil))
                    print("BetterResting [BED] Has RestoreToFullHealth: " .. tostring(samplePart.RestoreToFullHealth ~= nil))
                else
                    print("BetterResting [BED] ERROR: Could not get sample body part")
                end
                print("BetterResting [BED] Body parts count: " .. tostring(bodyParts:size()))
            end
            
            -- Gradual healing: reduce wound times incrementally (based on ISHealthPanel.lua)
            -- This allows true tick-by-tick healing without instantly removing wounds
            -- Use cooldown to prevent healing every single tick (heal every 6 ticks = ~0.1 seconds)
            local woundHealCooldown = 6  -- Heal wounds every 6 ticks instead of every tick
            
            for i = 1, bodyParts:size() do
                local part = bodyParts:get(i - 1)
                if part then
                    -- Get current health of body part (returns 0-100)
                    local partHealth = part:getHealth()
                    if partHealth and partHealth < 100.0 then
                        local partKey = tostring(i)
                        local lastWoundHeal = bodyPartHealCooldowns[partKey .. "_wound"] or 0
                        local partHealed = false
                        
                        -- Only heal wounds every N ticks to slow down healing
                        if updateCounter - lastWoundHeal >= woundHealCooldown then
                            -- Gradually reduce wound times (methods from ISHealthPanel.lua)
                            -- Very slow rates for gradual healing over time
                            -- Reduce scratch time
                            if part.getScratchTime and part.setScratchTime and part.setScratched then
                                local scratchTime = part:getScratchTime()
                                if scratchTime and scratchTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier  -- Very slow reduction
                                    local newTime = math.max(0, scratchTime - reduction)
                                    if newTime <= 0 then
                                        part:setScratched(false, true)
                                    else
                                        part:setScratchTime(newTime)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce cut time
                            if part.getCutTime and part.setCutTime and part.setCut then
                                local cutTime = part:getCutTime()
                                if cutTime and cutTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier  -- Very slow reduction
                                    local newTime = math.max(0, cutTime - reduction)
                                    if newTime <= 0 then
                                        part:setCut(false)
                                    else
                                        part:setCutTime(newTime)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce deep wound time
                            if part.getDeepWoundTime and part.setDeepWoundTime and part.setDeepWounded then
                                local deepWoundTime = part:getDeepWoundTime()
                                if deepWoundTime and deepWoundTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier  -- Very slow reduction
                                    local newTime = math.max(0, deepWoundTime - reduction)
                                    part:setDeepWoundTime(newTime)
                                    if newTime <= 0 then
                                        part:setDeepWounded(false)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce bleeding time
                            if part.getBleedingTime and part.setBleedingTime then
                                local bleedingTime = part:getBleedingTime()
                                if bleedingTime and bleedingTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier  -- Very slow reduction
                                    local newTime = math.max(0, bleedingTime - reduction)
                                    part:setBleedingTime(newTime)
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce muscle strain (stiffness) - based on ISHealthPanel.lua lines 276-278
                            if part.getStiffness and part.setStiffness then
                                local stiffness = part:getStiffness()
                                if stiffness and stiffness > 0 then
                                    local reduction = 0.005 * BetterResting.Config.BedMuscleFatigueReduction * 100  -- Very slow reduction for stiffness
                                    local newStiffness = math.max(0, stiffness - reduction)
                                    part:setStiffness(newStiffness)
                                    
                                    -- If stiffness reaches 0, remove it from fitness system (as per ISHealthPanel.lua)
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
                        
                        -- Gradually restore health (only when health is low and wounds are mostly healed)
                        -- Use RestoreToFullHealth but with much longer cooldown to prevent instant full heal
                        if part.RestoreToFullHealth and partHealth < 70.0 then
                            local lastHeal = bodyPartHealCooldowns[partKey] or 0
                            local healCooldown = math.max(1, math.floor(600 / BetterResting.Config.BedHPRegenMultiplier))  -- Much longer cooldown (10 seconds)
                            
                            if updateCounter - lastHeal >= healCooldown then
                                part:RestoreToFullHealth()
                                bodyPartHealCooldowns[partKey] = updateCounter
                                healedAny = true
                                
                                if updateCounter % 120 == 0 then
                                    print("BetterResting [BED] Gradually restored health for part " .. i .. " (was: " .. string.format("%.2f", partHealth) .. "%)")
                                end
                            end
                        elseif partHealed then
                            healedAny = true
                            if updateCounter % 120 == 0 then
                                print("BetterResting [BED] Gradually healing wounds on part " .. i .. " (health: " .. string.format("%.2f", partHealth) .. "%)")
                            end
                        end
                    end
                end
            end
        else
            if updateCounter and updateCounter % 120 == 0 then
                print("BetterResting [BED] ERROR: getBodyParts() returned nil")
            end
        end
        
        if not healedAny and updateCounter and updateCounter % 120 == 0 then
            print("BetterResting [BED] No healing applied - all parts may be at full health or methods not available")
        end
    end
    
    -- Reduce muscle fatigue faster
    local parts = bodyDamage:getBodyParts()
    if parts then
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            if part then
                -- Check if getPain method exists
                if part.getPain and part.setPain then
                    local pain = part:getPain()
                    if pain and pain > 0 then
                        -- Reduce pain faster
                        local reduction = pain * BetterResting.Config.BedMuscleFatigueReduction * 0.01
                        local newPain = math.max(0, pain - reduction)
                        part:setPain(newPain)
                        
                        -- Debug output every 2 seconds
                        if updateCounter and updateCounter % 120 == 0 then
                            print("BetterResting [BED] Reducing pain - Pain: " .. string.format("%.4f", pain) .. " -> " .. string.format("%.4f", newPain) .. " (Reduction: " .. string.format("%.4f", reduction) .. ")")
                        end
                    end
                end
            end
        end
    end
end

-- Main update loop - handles game mechanics AND UI
local updateCounter = 0
local lastStaminaCheck = 0
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
    
    -- Initialize player data
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

    -- Track rest type changes
    if data.lastRestType ~= restType then
        if restType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = BetterResting.getCurrentGameHours()
        elseif data.lastRestType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = 0
            data.wasFullStamina = false
        end
    end
    
    data.lastRestType = restType
    data.currentRestType = restType
    
    -- Process bonuses based on rest type (GAME MECHANICS)
    if restType == BetterResting.RestType.CHAIR then
        processChairResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.VEHICLE then
        processVehicleResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.BED then
        processBedResting(player, data, updateCounter)
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
            showBuffExpired("chair")
        end
    end
    
    -- UI: Show message when rest type changes (first time only)
    if restType ~= lastRestType and restType ~= BetterResting.RestType.FLOOR then
        print("BetterResting [CLIENT] Rest type changed to: " .. tostring(restType))
        local messages = {
            [BetterResting.RestType.CHAIR] = "Resting on furniture - Enhanced stamina recovery",
            [BetterResting.RestType.VEHICLE] = "Resting in vehicle - Maximum stamina recovery",
            [BetterResting.RestType.BED] = "Resting in bed - Health and muscle recovery",
        }
        
        if messages[restType] then
            print("BetterResting [CLIENT] Showing rest message: " .. messages[restType])
            HaloTextHelper.addTextWithArrow(player, messages[restType], true, 0, 100, 255)
        end
    end
    
    -- Show periodic stamina status while resting (every 10 seconds)
    if restType ~= BetterResting.RestType.FLOOR then
        if updateCounter - lastStaminaCheck >= 600 then -- Every ~10 seconds
            local stats = player:getStats()
            if stats then
                local stamina = nil
                if stats.getEndurance then
                    stamina = stats:getEndurance()
                elseif stats.getFatigue then
                    stamina = stats:getFatigue()
                end
                if stamina then
                    local staminaPercent = math.floor(stamina * 100)
                    print("BetterResting [STATUS] Resting on " .. tostring(restType) .. " - Stamina: " .. staminaPercent .. "%")
                    lastStaminaCheck = updateCounter
                end
            end
        end
    else
        lastStaminaCheck = updateCounter
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
            HaloTextHelper.addTextWithArrow(player, "I feel well rested", true, 0, 255, 0)
            clientBuffData.lastIndicatorTime = currentTime
        end
    end
end)

print("BetterResting client script loaded")
if writeLog then
    writeLog("BetterResting", "Client script loaded")
end

-- Show confirmation message when mod loads
local function showModConfirmation()
    local player = getPlayer()
    if player and not hasShownInitialMessage then
        -- Show a clear confirmation message (green: 0, 255, 0)
        HaloTextHelper.addTextWithArrow(player, "BetterResting Mod Loaded!", true, 0, 255, 0)
        print("BetterResting [CLIENT] Mod confirmation message displayed!")
        hasShownInitialMessage = true
    end
end

-- Initialize and show confirmation on game start
local function initBetterResting()
    local player = getPlayer()
    if not player then return end
    
    -- Show confirmation message
    if not hasShownInitialMessage then
        HaloTextHelper.addTextWithArrow(player, "BetterResting Mod Loaded!", true, 0, 255, 0)
        print("BetterResting [CLIENT] Mod loaded and initialized!")
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