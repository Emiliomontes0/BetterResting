-- BetterResting Shared Script
-- Configuration accessible by both client and server

BetterResting = BetterResting or {}
BetterResting.Version = "1.1"
BetterResting.ModID = "BetterResting"

-- Configuration values
BetterResting.Config = {
    -- Chair/Sofa bonuses
    ChairStaminaRegenMultiplier = 1.07,       -- 7% faster stamina regen on chairs
    ChairBuffDuration = 600,                  -- 10 minutes = 600 seconds (game time)
    ChairStaminaConsumptionReduction = 0.75,  -- 25% reduction when buff active
    MinChairRestTime = 0.1,
    MinBuffDuration = 0.1,
    MaxBuffDuration = 1.0,
    
    -- Vehicle bonuses
    VehicleStaminaRegenMultiplier = 1.10,     -- 10% faster stamina regen in vehicle
    VehicleStaminaConsumptionReduction = 0.5, -- 50% reduction while in vehicle
    
    -- Bed bonuses
    BedStaminaRegenMultiplier = 1.2,          -- 20% faster stamina regen in bed
    BedHPRegenMultiplier = 2.0,               -- 2x faster HP regen (gradual healing)
    BedMuscleFatigueReduction = 0.30,         -- 30% faster muscle fatigue recovery (increased from 15%)

}

-- Rest location types
BetterResting.RestType = {
    FLOOR = "floor",
    CHAIR = "chair",
    VEHICLE = "vehicle",
    BED = "bed",
}

-- Lookup tables for CustomItem detection (most reliable method)
-- Extracted from newtiledefinitions.tiles.txt - all objects with BedType parameter
BetterResting.BedCustomItems = {
    -- Tents
    ["Base.CampingTentKit2"] = true,
    ["Base.HideTent"] = true,
    ["Base.ImprovisedTentKit"] = true,
    ["Base.TentBlue"] = true,
    ["Base.TentBrown"] = true,
    ["Base.TentGreen"] = true,
    ["Base.TentYellow"] = true,
    -- Sleeping Bags
    ["Base.SleepingBag_BluePlaid"] = true,
    ["Base.SleepingBag_Camo"] = true,
    ["Base.SleepingBag_Cheap_Blue"] = true,
    ["Base.SleepingBag_Cheap_Green"] = true,
    ["Base.SleepingBag_Cheap_Green2"] = true,
    ["Base.SleepingBag_Green"] = true,
    ["Base.SleepingBag_GreenPlaid"] = true,
    ["Base.SleepingBag_Hide"] = true,
    ["Base.SleepingBag_HighQuality_Brown"] = true,
    ["Base.SleepingBag_RedPlaid"] = true,
    ["Base.SleepingBag_Spiffo"] = true,
    -- Beds and Cots
    ["Base.Mov_Cot"] = true,
    ["Base.Mov_Gurney"] = true,
    ["Mov_Gurney"] = true,  -- Some variants don't have Base. prefix
    -- Other bed-like objects
    ["Base.Mov_GymnMat"] = true,
    -- Coffins (treated as beds for resting)
    ["Base.Mov_FlatCoffin"] = true,
}

local gameTime
Events.OnGameTimeLoaded.Add(function()
    gameTime = GameTime.getInstance()
end)

-- Get current game time in hours
function BetterResting.getCurrentGameHours()
    if not gameTime then --checker incase api changes
        print("BetterResting [SHARED] ERROR: getGameTime() returned nil!")
        return 0 
    end
    return gameTime:getMultiplier()
end


-- Check if player is actually resting (not just standing on furniture)
-- Uses game's built-in resting detection methods from ISRestAction.lua
function BetterResting.isPlayerResting(player)
    if not player then return false end
    -- Use game's built-in resting detection methods (from ISRestAction.lua)
    -- These methods are set by the game's ISRestAction and other rest actions
    
    -- Check if player has isResting() method (set by ISRestAction:setIsResting())
    if player.isResting then
        local isResting = player:isResting()
        if isResting then
            return true
        end
    end
    
    -- Check if sitting on furniture (chairs, sofas, etc.)
    if player.isSittingOnFurniture then
        local isSittingOnFurniture = player:isSittingOnFurniture()
        if isSittingOnFurniture then
            return true
        end
    end
    
    -- Check if sitting on ground
    if player.isSitOnGround then
        local isSitOnGround = player:isSitOnGround()
        if isSitOnGround then
            return true
        end
    end
    
    -- Check if on bed
    if player.isOnBed then
        local isOnBed = player:isOnBed()
        if isOnBed then
    return true
        end
    end
    
    return false
end

-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    if not player then return BetterResting.RestType.FLOOR end
    
    -- First check: If player is moving, they're not resting - default to floor
    -- This fixes the bug where sleeping bag state persists after getting up
    if player.currentSpeed and player.currentSpeed > 0.0 then
        print("[BetterResting] detectRestType: Player is moving, returning FLOOR")
        return BetterResting.RestType.FLOOR
    end
    
    -- Also check if player is actually resting using game API
    local isActuallyResting = false
    if player.isResting then
        isActuallyResting = player:isResting()
    end
    if not isActuallyResting and player.isSittingOnFurniture then
        isActuallyResting = player:isSittingOnFurniture()
    end
    if not isActuallyResting and player.isSitOnGround then
        isActuallyResting = player:isSitOnGround()
    end
    if not isActuallyResting and player.getBed then
        isActuallyResting = (player:getBed() ~= nil)
    end
    
    if not isActuallyResting then
        print("[BetterResting] detectRestType: Player is not actually resting, returning FLOOR")
        return BetterResting.RestType.FLOOR
    end
    
    -- Priority 1: Check if in vehicle (using game API)
    local vehicle = player:getVehicle()
    if vehicle then
        print("[BetterResting] detectRestType: VEHICLE detected")
        return BetterResting.RestType.VEHICLE
    end
    
    -- Priority 2: Check if on bed (using game API from ISRestAction.lua)
    local isOnBed = false
    if player.isOnBed then
        isOnBed = player:isOnBed()
        print("[BetterResting] detectRestType: isOnBed() = " .. tostring(isOnBed))
    else
        print("[BetterResting] detectRestType: isOnBed method not available")
    end
    
    if isOnBed then
        print("[BetterResting] detectRestType: BED detected (via isOnBed)")
        return BetterResting.RestType.BED
    end
    
    -- Check bed object directly (for sleeping bags and other bed types)
    -- IMPORTANT: Validate that getBed() returns an actual bed, not seating furniture
    local bed = nil
    if player.getBed then
        bed = player:getBed()
        print("[BetterResting] detectRestType: getBed() = " .. tostring(bed))
        
        -- Validate that the bed object is actually a bed, not seating furniture
        if bed then
            local isActuallyBed = false
            
            -- Check sprite name to confirm it's a bed
            if bed.getSprite then
                local sprite = bed:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    if spriteName then
                        local spriteNameLower = tostring(spriteName):lower()
                        print("[BetterResting] detectRestType: bed object sprite: " .. spriteNameLower)
                        
                        -- Check if it's seating furniture (should NOT be treated as bed)
                        if spriteNameLower:find("seating") or 
                           spriteNameLower:find("chair") or 
                           spriteNameLower:find("sofa") or 
                           spriteNameLower:find("couch") or
                           spriteNameLower:find("stool") or
                           spriteNameLower:find("bench") or
                           spriteNameLower:find("seat") then
                            print("[BetterResting] detectRestType: getBed() returned seating furniture, ignoring")
                            bed = nil  -- Don't treat as bed
                        -- Check if it's actually a bed
                        elseif spriteNameLower:find("bed") or 
                               spriteNameLower:find("bedding") or 
                               spriteNameLower:find("sleeping") or
                               spriteNameLower:find("tent") or
                               spriteNameLower:find("cot") or
                               spriteNameLower:find("gurney") or
                               spriteNameLower:find("camping_") then  -- Check for any camping sprite (tents, sleeping bags, etc.)
                            isActuallyBed = true
                            print("[BetterResting] detectRestType: bed object sprite confirms it's a bed")
                        end
                    end
                end
            end
            
            -- If sprite check didn't confirm it's a bed, check CustomItem
            -- Only check if bed is still valid (not set to nil)
            if bed and not isActuallyBed and bed.getCustomItem then
                local customItem = bed:getCustomItem()
                print("[BetterResting] detectRestType: Checking CustomItem: " .. tostring(customItem))
                if customItem then
                    local customItemStr = nil
                    if type(customItem) == "string" then
                        customItemStr = customItem
                    elseif customItem.getType then
                        customItemStr = customItem:getType()
                    elseif customItem.getFullType then
                        customItemStr = customItem:getFullType()
                    end
                    
                    print("[BetterResting] detectRestType: CustomItem string: " .. tostring(customItemStr))
                    if customItemStr and BetterResting.BedCustomItems[customItemStr] then
                        isActuallyBed = true
                        print("[BetterResting] detectRestType: bed object CustomItem confirms it's a bed: " .. tostring(customItemStr))
                    else
                        print("[BetterResting] detectRestType: CustomItem not in BedCustomItems list")
                    end
                end
            end
            
            -- If we couldn't confirm it's a bed, don't treat it as one
            -- Only set to nil if bed is still valid (not already nil)
            if bed and not isActuallyBed then
                print("[BetterResting] detectRestType: getBed() returned object that is not confirmed as bed, ignoring")
                bed = nil
                    end
                end
            end
            
    if bed then
        print("[BetterResting] detectRestType: BED detected (via getBed)")
        return BetterResting.RestType.BED
    end
    
    -- Priority 3: Check if sitting on furniture (chairs/sofas using game API from ISRestAction.lua)
    local isSittingOnFurniture = false
    if player.isSittingOnFurniture then
        isSittingOnFurniture = player:isSittingOnFurniture()
        print("[BetterResting] detectRestType: isSittingOnFurniture() = " .. tostring(isSittingOnFurniture))
    else
        print("[BetterResting] detectRestType: isSittingOnFurniture method not available")
    end
    
    if isSittingOnFurniture then
        -- Check if the furniture object is actually a bed or a chair/sofa
        local furnitureObj = nil
        if player.getSitOnFurnitureObject then
            furnitureObj = player:getSitOnFurnitureObject()
            print("[BetterResting] detectRestType: getSitOnFurnitureObject() = " .. tostring(furnitureObj))
            
            if furnitureObj then
                local isSeatingFurniture = false
                local isBedObject = false
                
                -- PRIORITY 1: Check sprite name FIRST to identify seating furniture (chairs/sofas/couches)
                -- This prevents couches from being detected as beds even if they have bed properties
                if furnitureObj.getSprite then
                    local sprite = furnitureObj:getSprite()
                    if sprite then
                        local spriteName = sprite:getName()
                        if spriteName then
                            local spriteNameLower = tostring(spriteName):lower()
                            print("[BetterResting] detectRestType: furniture sprite name: " .. spriteNameLower)
                            
                            -- Check for seating furniture keywords (chairs, sofas, couches, etc.)
                            if spriteNameLower:find("seating") or 
                               spriteNameLower:find("chair") or 
                               spriteNameLower:find("sofa") or 
                               spriteNameLower:find("couch") or
                               spriteNameLower:find("stool") or
                               spriteNameLower:find("bench") or
                               spriteNameLower:find("seat") then
                                isSeatingFurniture = true
                                print("[BetterResting] detectRestType: furniture is seating furniture (chair/sofa/couch)")
                            -- Check for bed keywords
                            elseif spriteNameLower:find("bed") or 
                                   spriteNameLower:find("bedding") or 
                                   spriteNameLower:find("sleeping") then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture sprite indicates bed: " .. spriteNameLower)
                end
            end
                    end
                end
                
                -- PRIORITY 2: If not identified by sprite, check CustomItem
                if not isSeatingFurniture and not isBedObject and furnitureObj.getCustomItem then
                    local customItem = furnitureObj:getCustomItem()
                    if customItem then
                        local customItemStr = nil
                        if type(customItem) == "string" then
                            customItemStr = customItem
                        elseif customItem.getType then
                            customItemStr = customItem:getType()
                        elseif customItem.getFullType then
                            customItemStr = customItem:getFullType()
                        end
                        
                        if customItemStr then
                            if BetterResting.BedCustomItems[customItemStr] then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture CustomItem is bed: " .. tostring(customItemStr))
                        end
                    end
                end
            end
            
                -- PRIORITY 3: Only check bed properties if sprite didn't indicate seating furniture
                -- This prevents couches (which have bed properties) from being detected as beds
                if not isSeatingFurniture and not isBedObject then
                    if furnitureObj.getProperties then
                        local props = furnitureObj:getProperties()
                        if props then
                            if props:get("bed") or props:get("BedType") then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture has bed property")
                            end
                        end
                    end
                    if furnitureObj.bed or furnitureObj.BedType then
                        isBedObject = true
                        print("[BetterResting] detectRestType: furniture has bed property (direct)")
                end
            end
            
                if isBedObject then
                    print("[BetterResting] detectRestType: BED detected (furniture is bed)")
                    return BetterResting.RestType.BED
                end
            end
        end
        
        print("[BetterResting] detectRestType: CHAIR detected (via isSittingOnFurniture)")
        return BetterResting.RestType.CHAIR
    end
    
    -- Fallback: Default to floor if none of the above conditions are met
    print("[BetterResting] detectRestType: FLOOR (fallback)")
    return BetterResting.RestType.FLOOR
end



-- Check if we're on the server side (works in both single-player and multiplayer)
local function isServerSide()
    local result = false
    if isServer and type(isServer) == "function" then
        result = isServer()
        print(string.format("[BetterResting SHARED] isServer() check: %s", tostring(result)))
    elseif isClient and type(isClient) == "function" then
        result = not isClient()
        print(string.format("[BetterResting SHARED] isClient() check: %s, so server side: %s", tostring(isClient()), tostring(result)))
    else
        -- Default: assume server (for single-player compatibility)
        result = true
        print("[BetterResting SHARED] No isServer/isClient functions, assuming server side")
    end
    return result
end

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

-- Track previous values to detect unexpected changes
local previousValues = {}

-- Apply chair buff when stamina is full
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
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
    
    applyChairBuff(player, data)
end

-- Process vehicle resting bonuses
local function processVehicleResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

-- Process bed resting bonuses
local function processBedResting(player, data, updateCounter)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    
    local stats = player:getStats()
    if stats then
        local stamina = stats:get(CharacterStat.ENDURANCE)
        if stamina and stamina < 1.0 then
            local baseRegen = 0.001
            local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
            local newStamina = math.min(1.0, stamina + bonusRegen)
            stats:set(CharacterStat.ENDURANCE, newStamina)
        end
    end
    
    local health = bodyDamage:getHealth() / 100.0
    if health and health < 1.0 then
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            local woundHealCooldown = 6
            local playerKey = tostring(player:getPlayerNum())
            
            for i = 1, bodyParts:size() do
                local part = bodyParts:get(i - 1)
                if part then
                    local partHealth = part:getHealth()
                    if partHealth and partHealth < 100.0 then
                        local partKey = playerKey .. "_" .. tostring(i)
                        local lastWoundHeal = bodyPartHealCooldowns[partKey .. "_wound"] or 0
                        local partHealed = false
                        
                        if updateCounter - lastWoundHeal >= woundHealCooldown then
                            -- Reduce scratch time
                            if part.getScratchTime and part.setScratchTime and part.setScratched then
                                local scratchTime = part:getScratchTime()
                                if scratchTime and scratchTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
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
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
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
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
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
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, bleedingTime - reduction)
                                    part:setBleedingTime(newTime)
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce muscle strain (stiffness)
                            if part.getStiffness and part.setStiffness then
                                local stiffness = part:getStiffness()
                                if stiffness and stiffness > 0 then
                                    local oldStiffness = stiffness
                                    local partKeyStiff = playerKey .. "_part" .. i .. "_stiffness"
                                    local previousStiffness = previousValues[partKeyStiff]
                                    
                                    if previousStiffness and math.abs(stiffness - previousStiffness) > 0.5 then
                                        print(string.format("[BetterResting SHARED] WARNING: Stiffness changed unexpectedly! Expected ~%.2f but got %.2f", 
                                            previousStiffness, stiffness))
                                    end
                                    
                                    local reduction = 0.005 * BetterResting.Config.BedMuscleFatigueReduction * 100
                                    local newStiffness = math.max(0, stiffness - reduction)
                                    
                                    if updateCounter % 60 == 0 then
                                        print(string.format("[BetterResting SHARED] Part %d: Stiffness %.2f -> %.2f (tick %d)", 
                                            i, oldStiffness, newStiffness, updateCounter))
                                    end
                                    
                                    part:setStiffness(newStiffness)
                                    
                                    -- Immediately verify and log
                                    local verifyStiffness = part:getStiffness()
                                    if math.abs(verifyStiffness - newStiffness) > 0.01 then
                                        print(string.format("[BetterResting SHARED] WARNING: Stiffness mismatch! Set %.2f but got %.2f (diff: %.2f)", 
                                            newStiffness, verifyStiffness, verifyStiffness - newStiffness))
                                        -- Try setting again
                                        part:setStiffness(newStiffness)
                                        local verify2 = part:getStiffness()
                                        if math.abs(verify2 - newStiffness) > 0.01 then
                                            print(string.format("[BetterResting SHARED] CRITICAL: Stiffness still wrong after retry! Something is resetting it!"))
                                        end
                                    end
                                    
                                    previousValues[partKeyStiff] = newStiffness
                                    
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
                        
                        if part.RestoreToFullHealth and partHealth < 70.0 then
                            local lastHeal = bodyPartHealCooldowns[partKey] or 0
                            local healCooldown = math.max(1, math.floor(600 / BetterResting.Config.BedHPRegenMultiplier))
                            
                            if updateCounter - lastHeal >= healCooldown then
                                part:RestoreToFullHealth()
                                bodyPartHealCooldowns[partKey] = updateCounter
                            end
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

-- Main server update loop - handles game mechanics (runs in shared script with server check)
local updateCounter = 0
local hasLoggedStart = false

Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    -- Check if we're on server side
    local onServer = isServerSide()
    
    -- Log first time to confirm detection
    if not hasLoggedStart then
        print(string.format("[BetterResting SHARED] OnPlayerUpdate handler - isServerSide: %s", tostring(onServer)))
        hasLoggedStart = true
    end
    
    -- Only run game mechanics on server side
    if not onServer then
        if updateCounter == 0 then
            print("[BetterResting SHARED] WARNING: OnPlayerUpdate running on CLIENT side - game mechanics disabled!")
        end
        return
    end
    
    -- Log first time to confirm it's running on server
    if updateCounter == 0 then
        print("[BetterResting SHARED] OnPlayerUpdate handler is ACTIVE on server side!")
    end
    
    updateCounter = updateCounter + 1
    
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

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
    
    if restType == BetterResting.RestType.CHAIR then
        processChairResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.VEHICLE then
        processVehicleResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.BED then
        if updateCounter % 60 == 0 then
            print(string.format("[BetterResting SHARED] Processing BED resting (tick %d)", updateCounter))
        end
        processBedResting(player, data, updateCounter)
    end
    
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

-- Use both print and writeLog to ensure we see output
print("=========================================")
print("BetterResting shared script loaded - Version " .. BetterResting.Version)
print("BetterResting - GAME MECHANICS ENABLED IN SHARED SCRIPT")
print("=========================================")
if writeLog then
    writeLog("BetterResting", "Shared script loaded - Version " .. BetterResting.Version)
end

-- Also verify on game start
Events.OnGameStart.Add(function()
    print("BetterResting [EVENT] OnGameStart fired - Shared script confirmed loaded!")
    print("BetterResting [SHARED] isServer check: " .. tostring(isServer and isServer() or "function not available"))
    print("BetterResting [SHARED] isClient check: " .. tostring(isClient and isClient() or "function not available"))
    print("BetterResting [SHARED] isServerSide() = " .. tostring(isServerSide()))
end)