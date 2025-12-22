-- BetterResting Shared Script
-- Configuration accessible by both client and server

BetterResting = BetterResting or {}
BetterResting.Version = "1.0"
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

-- Get current game time in hours
function BetterResting.getCurrentGameHours()
    local gameTime = getGameTime()
    if not gameTime then 
        print("BetterResting [SHARED] ERROR: getGameTime() returned nil!")
        return 0 
    end
    return gameTime:getWorldAgeHours()
end

-- Check if player is actually resting (not just standing on furniture)
function BetterResting.isPlayerResting(player)
    if not player then return false end
    
    -- Check if player is moving - if moving, they're definitely not resting
    -- Try multiple methods to detect movement
    local isMoving = false
    
    -- Method 1: Check velocity
    if player.getVelocity then
        local vx, vy, vz = player:getVelocity()
        if vx and vy then
            local speed = math.sqrt(vx * vx + vy * vy)
            if speed > 0.01 then  -- If moving faster than threshold
                isMoving = true
            end
        end
    end
    
    -- Method 2: Check if player is walking/running
    if not isMoving and player.isMoving then
        isMoving = player:isMoving()
    end
    
    -- Method 3: Check movement state variable
    if not isMoving and player.getVariableBoolean then
        local isWalking = player:getVariableBoolean("IsWalking")
        local isRunning = player:getVariableBoolean("IsRunning")
        if isWalking or isRunning then
            isMoving = true
        end
    end
    
    -- If player is moving, they're not resting
    if isMoving then
        return false
    end
    
    -- If player is not moving, they might be resting
    -- Additional check: if they're sitting on ground, they're definitely resting
    if player.getVariableBoolean then
        local isSitOnGround = player:getVariableBoolean("IsSitOnGround")
        if isSitOnGround then
            return true
        end
    end
    
    -- If not moving and not explicitly sitting, still allow resting
    -- (player might be lying in bed or sitting on furniture)
    return true
end

-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    if not player then return BetterResting.RestType.FLOOR end
    
    -- Check if in vehicle (no movement check needed for vehicles)
    local vehicle = player:getVehicle()
    if vehicle then
        return BetterResting.RestType.VEHICLE
    end
    
    -- Check current square for furniture
    local square = player:getCurrentSquare()
    if not square then return BetterResting.RestType.FLOOR end
    
    local objects = square:getObjects()
    if not objects then return BetterResting.RestType.FLOOR end
    
    -- Track if we've found a chair in this square (to prevent bed detection)
    local foundChairInSquare = false
    
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            -- Try multiple methods to identify the object
            local customItem = nil
            local customName = nil
            local item = nil
            local objectType = nil
            
            -- PRIORITY 1: Check CustomItem first (most reliable method)
            if obj.getCustomItem then
                customItem = obj:getCustomItem()
                if customItem then
                    local customItemStr = nil
                    if type(customItem) == "string" then
                        customItemStr = customItem
                    elseif customItem.getType then
                        customItemStr = customItem:getType()
                    elseif customItem.getFullType then
                        customItemStr = customItem:getFullType()
                    else
                        customItemStr = tostring(customItem)
                    end
                    
                    if customItemStr then
                        -- Check if it's a known bed CustomItem
                        if BetterResting.BedCustomItems[customItemStr] then
                            return BetterResting.RestType.BED
                        end
                    end
                end
            end
            
            -- Try getCustomName
            if obj.getCustomName then
                customName = obj:getCustomName()
            end
            
            -- Try getItem (for IsoThumpable objects)
            if obj.getItem then
                item = obj:getItem()
            end
            
            -- Try getType or getClass
            if obj.getType then
                objectType = obj:getType()
            elseif obj.getClass then
                objectType = obj:getClass()
            end
            
            -- Get sprite early so we can use it for both chair and bed detection
            local sprite = obj:getSprite()
            
            -- PRIORITY 2: Check if object has bed or chair properties (from tiles file)
            local hasBedProperty = false
            local hasChairProperty = false
            local bedType = nil
            
            -- Try to get BedType property directly
            -- Wrap in pcall to safely handle API errors (props:get may not accept string arguments)
            if obj.getProperties then
                local props = obj:getProperties()
                if props then
                    -- Safely try to get "bed" property
                    local success, result = pcall(function() return props:get("bed") end)
                    if success and result then
                        hasBedProperty = true
                    end
                    
                    -- Safely try to get chair properties
                    local success1, result1 = pcall(function() return props:get("chairS") end)
                    local success2, result2 = pcall(function() return props:get("chair") end)
                    if (success1 and result1) or (success2 and result2) then
                        hasChairProperty = true
                    end
                    
                    -- Safely try to get BedType property
                    local success3, result3 = pcall(function() return props:get("BedType") end)
                    if success3 and result3 then
                        bedType = result3
                    end
                end
            end
            
            -- Also check direct properties
            if obj.bed then
                hasBedProperty = true
            end
            if obj.chairS or obj.chair then
                hasChairProperty = true
            end
            if obj.BedType then
                bedType = obj.BedType
            end
            
            
            -- Check chair properties FIRST (chairs can have BedType but should be treated as chairs)
            -- Only apply to chairs if player is actually resting (not walking through)
            -- IMPORTANT: If object has chair property, skip bed detection entirely (chairs can have BedType)
            local isChairObject = hasChairProperty
            
            if hasChairProperty then
                foundChairInSquare = true  -- Mark that we found a chair in this square
                if BetterResting.isPlayerResting(player) then
                    return BetterResting.RestType.CHAIR
                else
                    -- Don't check beds if this is a chair (even if moving, it's still a chair)
                    -- Skip bed detection for this object
                    hasBedProperty = false  -- Prevent bed detection for chairs
                    bedType = nil  -- Clear BedType for chairs
                end
            end
            
            -- Check bed properties (only if not a chair)
            if hasBedProperty and not isChairObject then
                return BetterResting.RestType.BED
            end
            
            -- PRIORITY 3: Check CustomName for chairs BEFORE BedType
            -- This is important because chairs/picnic tables can have BedType=badBed
            -- but should be treated as chairs based on their CustomName
            if customName then
                local nameLower = customName:lower()
                    if nameLower:find("chair") or 
                   nameLower:find("stool") or 
                   nameLower:find("bench") or 
                   nameLower:find("couch") or 
                   nameLower:find("sofa") or 
                   nameLower:find("seat") or 
                   nameLower:find("table") or 
                   nameLower:find("picnic") or 
                   nameLower:find("picknic") or 
                   nameLower:find("coffin") or 
                   nameLower:find("ottoman") or 
                   nameLower:find("pew") then
                    foundChairInSquare = true  -- Mark that we found a chair in this square
                    if BetterResting.isPlayerResting(player) then
                        return BetterResting.RestType.CHAIR
                    else
                        -- Continue checking other objects, but skip bed detection
                        bedType = nil  -- Clear BedType for chairs
                    end
                end
            end
            
            -- PRIORITY 4: Check sprite name for chairs BEFORE BedType
            -- Some chairs don't have CustomName but have BedType=badBed
            -- We need to check sprite names to identify them as chairs
            if sprite then
                local spriteNameObj = sprite:getName()
                if spriteNameObj then
                    local spriteName = spriteNameObj:lower()
                    if spriteName then
                        -- Check for chairs/sofas/couches/seating FIRST (before beds)
                        if spriteName:find("chair") or 
                           spriteName:find("chairs") or
                           spriteName:find("sofa") or 
                           spriteName:find("couch") or
                           spriteName:find("seat") or
                           spriteName:find("furniture_seating") or
                           spriteName:find("seating") or
                           spriteName:find("bench") or
                           spriteName:find("stool") or
                           spriteName:find("barstool") or
                           spriteName:find("bar_stool") or
                           spriteName:find("bar stool") or
                           spriteName:find("50s_barstool") or
                           spriteName:find("50s barstool") or
                           spriteName:find("ottoman") or
                           spriteName:find("pew") or
                           spriteName:find("picnic") or
                           spriteName:find("picknic") or
                           spriteName:find("picknic_table") or
                           spriteName:find("picknic table") or
                           spriteName:find("table") or
                           spriteName:find("coffin") or
                           spriteName:find("mat") or
                           spriteName:find("gymnmat") or
                           spriteName:find("hay") or
                           spriteName:find("stacked_hay") or
                           spriteName:find("stacked hay") or
                           spriteName:find("shelter") or
                           spriteName:find("stump") or
                           spriteName:find("chopping_block") or
                           spriteName:find("chopping block") then
                            foundChairInSquare = true  -- Mark that we found a chair in this square
                            if BetterResting.isPlayerResting(player) then
                                return BetterResting.RestType.CHAIR
                            else
                                -- Continue checking other objects, but skip bed detection
                                bedType = nil  -- Clear BedType for chairs
                            end
                        end
                    end
                end
            end
            
            -- Check BedType property (but only if it's not a chair)
            -- Note: Chairs can have BedType=badBed but should be treated as CHAIR, not BED
            -- We check this AFTER CustomName and sprite name to avoid false positives
            -- IMPORTANT: If we found a chair in this square, don't check BedType (chairs can have BedType)
            if bedType and not isChairObject and not foundChairInSquare then
                return BetterResting.RestType.BED
            end
            
            -- If we have an item, check its type
            if item then
                local itemType = nil
                if item.getType then
                    itemType = item:getType()
                elseif item.getFullType then
                    itemType = item:getFullType()
                end
                if itemType then
                    local itemTypeLower = itemType:lower()
                    
                    -- Check for beds
                    if itemTypeLower:find("sleepingbag") or 
                       itemTypeLower:find("tent") or 
                       itemTypeLower:find("cot") or 
                       itemTypeLower:find("gurney") then
                        return BetterResting.RestType.BED
                    end
                    
                    -- Check for chairs
                    if itemTypeLower:find("coffin") or 
                       itemTypeLower:find("stool") or 
                       itemTypeLower:find("chair") or 
                       itemTypeLower:find("bench") or
                       itemTypeLower:find("table") then
                        foundChairInSquare = true  -- Mark that we found a chair in this square
                        if BetterResting.isPlayerResting(player) then
                            return BetterResting.RestType.CHAIR
                        else
                            -- Continue checking other objects, but skip bed detection
                            bedType = nil  -- Clear BedType for chairs
                        end
                    end
                end
            end
            
            -- CustomItem already checked at PRIORITY 1, skip duplicate check
            
            -- Check CustomName for beds (chairs already checked above)
            if customName then
                local nameLower = customName:lower()
                if nameLower:find("bed") or 
                   nameLower:find("tent") or 
                   nameLower:find("sleeping") or 
                   nameLower:find("cot") or 
                   nameLower:find("gurney") then
                    return BetterResting.RestType.BED
                end
            end
            
            -- Fallback: Check sprite name for beds only (chairs already checked earlier)
            -- Only check if sprite wasn't already checked above
            if sprite then
                local spriteNameObj = sprite:getName()
                if spriteNameObj then
                    local spriteName = spriteNameObj:lower()
                    if spriteName then
                        -- Check for beds (comprehensive list from game files)
                        -- Note: camping_02_* sprites are sleeping bags (camping_02_49, camping_02_50, etc.)
                        if spriteName:find("bed") or 
                           spriteName:find("furniture_bed") or
                           spriteName:find("furniture_sleeping") or
                           spriteName:find("beds") or
                           spriteName:find("tent") or
                           spriteName:find("sleeping") or
                           spriteName:find("sleepingbag") or
                           spriteName:find("sleeping_bag") or
                           spriteName:find("sleeping bag") or
                           spriteName:find("cot") or
                           spriteName:find("gurney") or
                           spriteName:find("camping_02_") then
                            return BetterResting.RestType.BED
                        end
                    end
                end
            end
        end
    end
    
    return BetterResting.RestType.FLOOR
end

-- Use both print and writeLog to ensure we see output
print("BetterResting shared script loaded - Version " .. BetterResting.Version)
if writeLog then
    writeLog("BetterResting", "Shared script loaded - Version " .. BetterResting.Version)
end

-- Also verify on game start
Events.OnGameStart.Add(function()
    print("BetterResting [EVENT] OnGameStart fired - Shared script confirmed loaded!")
end)