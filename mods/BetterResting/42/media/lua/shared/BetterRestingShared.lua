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
    BedMuscleFatigueReduction = 0.15,         -- 15% faster muscle fatigue recovery

}

-- Rest location types
BetterResting.RestType = {
    FLOOR = "floor",
    CHAIR = "chair",
    VEHICLE = "vehicle",
    BED = "bed",
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

-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    if not player then return BetterResting.RestType.FLOOR end
    
    -- Check if in vehicle
    local vehicle = player:getVehicle()
    if vehicle then
        return BetterResting.RestType.VEHICLE
    end
    
    -- Check current square for furniture
    local square = player:getCurrentSquare()
    if not square then return BetterResting.RestType.FLOOR end
    
    local objects = square:getObjects()
    if not objects then return BetterResting.RestType.FLOOR end
    
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            -- Try multiple methods to identify the object
            local customItem = nil
            local customName = nil
            local item = nil
            local objectType = nil
            
            -- Try getCustomItem
            if obj.getCustomItem then
                customItem = obj:getCustomItem()
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
            
            -- Check if object has bed or chair properties (from tiles file)
            local hasBedProperty = false
            local hasChairProperty = false
            local bedType = nil
            
            -- Try to get BedType property directly
            if obj.getProperties then
                local props = obj:getProperties()
                if props then
                    if props:get("bed") then
                        hasBedProperty = true
                    end
                    if props:get("chairS") or props:get("chair") then
                        hasChairProperty = true
                    end
                    if props:get("BedType") then
                        bedType = props:get("BedType")
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
            
            -- Debug: Print all object info
            print("BetterResting [DEBUG] Object #" .. i .. " - Type: " .. tostring(objectType) .. ", CustomItem: " .. tostring(customItem) .. ", CustomName: " .. tostring(customName) .. ", Item: " .. tostring(item) .. ", hasBed: " .. tostring(hasBedProperty) .. ", hasChair: " .. tostring(hasChairProperty) .. ", BedType: " .. tostring(bedType))
            
            -- Check chair properties FIRST (chairs can have BedType but should be treated as chairs)
            if hasChairProperty then
                print("BetterResting [DEBUG] Detected CHAIR via chair property")
                return BetterResting.RestType.CHAIR
            end
            
            -- Check bed properties
            if hasBedProperty then
                print("BetterResting [DEBUG] Detected BED via bed property")
                return BetterResting.RestType.BED
            end
            
            -- Check BedType property (but only if it's not a chair)
            -- Note: Chairs can have BedType=badBed but should be treated as CHAIR, not BED
            if bedType and not hasChairProperty then
                print("BetterResting [DEBUG] Detected BED via BedType property: " .. tostring(bedType))
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
                    print("BetterResting [DEBUG] Item type: " .. tostring(itemType))
                    local itemTypeLower = itemType:lower()
                    
                    -- Check for beds
                    if itemTypeLower:find("sleepingbag") or 
                       itemTypeLower:find("tent") or 
                       itemTypeLower:find("cot") or 
                       itemTypeLower:find("gurney") then
                        print("BetterResting [DEBUG] Detected BED via Item: " .. tostring(itemType))
                        return BetterResting.RestType.BED
                    end
                    
                    -- Check for chairs
                    if itemTypeLower:find("coffin") or 
                       itemTypeLower:find("stool") or 
                       itemTypeLower:find("chair") or 
                       itemTypeLower:find("bench") or
                       itemTypeLower:find("table") then
                        print("BetterResting [DEBUG] Detected CHAIR via Item: " .. tostring(itemType))
                        return BetterResting.RestType.CHAIR
                    end
                end
            end
            
            -- Check CustomItem for beds
            if customItem then
                local itemType = nil
                if type(customItem) == "string" then
                    itemType = customItem
                elseif customItem.getType then
                    itemType = customItem:getType()
                elseif customItem.getFullType then
                    itemType = customItem:getFullType()
                else
                    itemType = tostring(customItem)
                end
                
                if itemType then
                    local itemTypeLower = itemType:lower()
                    if itemTypeLower:find("sleepingbag") or 
                       itemTypeLower:find("tent") or 
                       itemTypeLower:find("cot") or 
                       itemTypeLower:find("gurney") then
                        print("BetterResting [DEBUG] Detected BED via CustomItem: " .. tostring(itemType))
                        return BetterResting.RestType.BED
                    end
                end
            end
            
            -- Check CustomItem for chairs
            if customItem then
                local itemType = nil
                if type(customItem) == "string" then
                    itemType = customItem
                elseif customItem.getType then
                    itemType = customItem:getType()
                elseif customItem.getFullType then
                    itemType = customItem:getFullType()
                else
                    itemType = tostring(customItem)
                end
                
                if itemType then
                    local itemTypeLower = itemType:lower()
                    if itemTypeLower:find("coffin") or 
                       itemTypeLower:find("stool") or 
                       itemTypeLower:find("chair") or 
                       itemTypeLower:find("bench") then
                        print("BetterResting [DEBUG] Detected CHAIR via CustomItem: " .. tostring(itemType))
                        return BetterResting.RestType.CHAIR
                    end
                end
            end
            
            -- Check CustomName for beds
            if customName then
                local nameLower = customName:lower()
                if nameLower:find("bed") or 
                   nameLower:find("tent") or 
                   nameLower:find("sleeping") or 
                   nameLower:find("cot") or 
                   nameLower:find("gurney") then
                    print("BetterResting [DEBUG] Detected BED via CustomName: " .. customName)
                    return BetterResting.RestType.BED
                end
            end
            
            -- Check CustomName for chairs
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
                    print("BetterResting [DEBUG] Detected CHAIR via CustomName: " .. customName)
                    return BetterResting.RestType.CHAIR
                end
            end
            
            -- Fallback: Safely get sprite name with nil checks
            local sprite = obj:getSprite()
            if sprite then
                local spriteNameObj = sprite:getName()
                if spriteNameObj then
                    local spriteName = spriteNameObj:lower()
                    if spriteName then
                        print("BetterResting [DEBUG] Checking sprite: " .. tostring(spriteName))
                        
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
                            print("BetterResting [DEBUG] Detected BED via sprite: " .. tostring(spriteName))
                            return BetterResting.RestType.BED
                        end
                        
                        -- Check for chairs/sofas/couches/seating (comprehensive list from game files)
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
                            print("BetterResting [DEBUG] Detected CHAIR: " .. tostring(spriteName))
                            return BetterResting.RestType.CHAIR
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