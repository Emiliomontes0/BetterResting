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
    NOT_RESTING = "not_resting"
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

function BetterResting.isPlayerResting(player)
    -- Check if player has isResting() method (set by ISRestAction:setIsResting())
    if player.isResting then
        local isResting = player:isResting()
        if isResting then
            return true
        end
    end
    return false
end
function BetterResting.isActuallyVehicle(player)
    local vehicle = player:getVehicle()
    if vehicle then
        return BetterResting.RestType.VEHICLE
    end
    return BetterResting.RestType.NOT_RESTING
end

function BetterResting.isActuallyBed(player)
    local bed = nil
    if player.getBed then
        bed = player:getBed()
        if bed then
            local isActuallyBed = false
            if bed.getSprite then
                local sprite = bed:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    if spriteName then
                        local spriteNameLower = tostring(spriteName):lower()
                        
                        if spriteNameLower:find("seating") or 
                           spriteNameLower:find("chair") or 
                           spriteNameLower:find("sofa") or 
                           spriteNameLower:find("couch") or
                           spriteNameLower:find("stool") or
                           spriteNameLower:find("bench") or
                           spriteNameLower:find("seat") then
                            bed = nil 
                        elseif spriteNameLower:find("bed") or 
                               spriteNameLower:find("bedding") or 
                               spriteNameLower:find("sleeping") or
                               spriteNameLower:find("tent") or
                               spriteNameLower:find("cot") or
                               spriteNameLower:find("gurney") or
                               spriteNameLower:find("camping_") then  
                            isActuallyBed = true
                        end
                    end
                end
            end
            
            if bed and not isActuallyBed and bed.getCustomItem then
                local customItem = bed:getCustomItem()
                if customItem then
                    local customItemStr = nil
                    if type(customItem) == "string" then
                        customItemStr = customItem
                    elseif customItem.getType then
                        customItemStr = customItem:getType()
                    elseif customItem.getFullType then
                        customItemStr = customItem:getFullType()
                    end
                    
                    if customItemStr and BetterResting.BedCustomItems[customItemStr] then
                        isActuallyBed = true
                        -- print("[BetterResting] detectRestType: bed object CustomItem confirms it's a bed: " .. tostring(customItemStr))
                    else

                    end
                end
            end
            
            if bed and not isActuallyBed then
                -- print("[BetterResting] detectRestType: getBed() returned object that is not confirmed as bed, ignoring")
                bed = nil
                    end
                end
            end
            
    if bed then
        -- print("[BetterResting] detectRestType: BED detected (via getBed)")
        return BetterResting.RestType.BED
    end
    
    return nil  -- Explicitly return nil if no bed found
end

function BetterResting.isActuallyChair(player)
    local isSittingOnFurniture = false
    if player.isSittingOnFurniture then
        isSittingOnFurniture = player:isSittingOnFurniture()
        -- print("[BetterResting] detectRestType: isSittingOnFurniture() = " .. tostring(isSittingOnFurniture))
    else
        -- print("[BetterResting] detectRestType: isSittingOnFurniture method not available")
    end
    
    if isSittingOnFurniture then
        local furnitureObj = nil
        if player.getSitOnFurnitureObject then
            furnitureObj = player:getSitOnFurnitureObject()
            -- print("[BetterResting] detectRestType: getSitOnFurnitureObject() = " .. tostring(furnitureObj))
            
            if furnitureObj then
                local isSeatingFurniture = false
                local isBedObject = false
                
                -- PRIORITY 1: Check sprite name FIRST to identify seating furniture (chairs/sofas/couches)
                if furnitureObj.getSprite then
                    local sprite = furnitureObj:getSprite()
                    if sprite then
                        local spriteName = sprite:getName()
                        if spriteName then
                            local spriteNameLower = tostring(spriteName):lower()
                            -- print("[BetterResting] detectRestType: furniture sprite name: " .. spriteNameLower)
                            
                            if spriteNameLower:find("seating") or 
                               spriteNameLower:find("chair") or 
                               spriteNameLower:find("sofa") or 
                               spriteNameLower:find("couch") or
                               spriteNameLower:find("stool") or
                               spriteNameLower:find("bench") or
                               spriteNameLower:find("seat") then
                                isSeatingFurniture = true
                                -- print("[BetterResting] detectRestType: furniture is seating furniture (chair/sofa/couch)")
                            elseif spriteNameLower:find("bed") or 
                                   spriteNameLower:find("bedding") or 
                                   spriteNameLower:find("sleeping") then
                                isBedObject = true
                                -- print("[BetterResting] detectRestType: furniture sprite indicates bed: " .. spriteNameLower)
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
                                -- print("[BetterResting] detectRestType: furniture CustomItem is bed: " .. tostring(customItemStr))
                        end
                    end
                end
            end
            
                -- PRIORITY 3: Only check bed properties if sprite didn't indicate seating furniture
                if not isSeatingFurniture and not isBedObject then
                    if furnitureObj.getProperties then
                        local props = furnitureObj:getProperties()
                        if props then
                            if props:get("bed") or props:get("BedType") then
                                isBedObject = true
                                -- print("[BetterResting] detectRestType: furniture has bed property")
                            end
                        end
                    end
                    if furnitureObj.bed or furnitureObj.BedType then
                        isBedObject = true
                        -- print("[BetterResting] detectRestType: furniture has bed property (direct)")
                end
            end
            
                if isBedObject then
                    -- print("[BetterResting] detectRestType: BED detected (furniture is bed)")
                    return BetterResting.RestType.BED
                end
            end
        end
        
        -- print("[BetterResting] detectRestType: CHAIR detected (via isSittingOnFurniture)")
        return BetterResting.RestType.CHAIR
    end
end

function BetterResting.tileCheck(player)
    if not player then return nil end
    
    local square = player:getCurrentSquare()
    if not square then return nil end
    
    local objects = square:getObjects()
    if not objects then return nil end
    
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj.getSprite then
            local sprite = obj:getSprite()
            if sprite then
                local spriteName = sprite:getName()
                if spriteName then
                    local spriteNameStr = tostring(spriteName)
                    -- Use the helper function from sprite_lookup.lua
                    local restType = BetterResting.getRestTypeFromSprite(spriteNameStr)
                    if restType then
                        return restType
                    end
                end
            end
        end
    end
    
    return nil
end

-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    local isActuallyResting = BetterResting.isPlayerResting(player)

    --first check Method
    if BetterResting.isActuallyVehicle(player) == BetterResting.RestType.VEHICLE then
        return BetterResting.RestType.VEHICLE
    end

    -- Check if player is moving - if so, they're not resting (prevents false positives from being on same tile as furniture)
    if player.currentSpeed and player.currentSpeed > 0.0 then
        return BetterResting.RestType.NOT_RESTING
    end

    -- Check beds and chairs if player is resting
    if isActuallyResting then
        local bedResult = BetterResting.isActuallyBed(player)
        if bedResult == BetterResting.RestType.BED then
            return BetterResting.RestType.BED
        end

        local chairResult = BetterResting.isActuallyChair(player)
        if chairResult == BetterResting.RestType.CHAIR then
            return BetterResting.RestType.CHAIR
        elseif chairResult == BetterResting.RestType.BED then
            return BetterResting.RestType.BED
        end

        if player.isSitOnGround() then
            return BetterResting.RestType.FLOOR
        end
    end

    -- Fallback: Check sprite lookup tables (works even if isPlayerResting returns false)
    local tileResult = BetterResting.tileCheck(player)
    if tileResult then
        return tileResult
    end

    -- If not resting and no sprite match, return NOT_RESTING
    if not isActuallyResting then
        return BetterResting.RestType.NOT_RESTING
    end

    -- Final fallback
    return BetterResting.RestType.NOT_RESTING
end

StiffnessData = {}
StiffnessData.__index = StiffnessData

function StiffnessData:new(player)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.bodyParts = {}
    o.tolerance = 0.01
    
    return o
end

function StiffnessData:getPlayer()
    return self.player
end

function StiffnessData:getPlayerNum()
    return self.playerNum
end

-- Derived class for bed resting stiffness management
BedStiffnessAction = {}
BedStiffnessAction.__index = BedStiffnessAction
setmetatable(BedStiffnessAction, {__index = StiffnessData})

function BedStiffnessAction:new(player, updateCounter)
    local o = StiffnessData.new(StiffnessData, player)
    setmetatable(o, self)
    self.__index = self
    
    o.updateCounter = updateCounter
    o.reductionRate = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
    o.bodyPartsModified = false
    
    return o
end

function BedStiffnessAction:processStiffness(bodyPart, partIndex, expectedStiffness)
    if not bodyPart or not bodyPart.getStiffness or not bodyPart.setStiffness then
        return nil
    end
    
    local stiffness = bodyPart:getStiffness()
    local partKey = tostring(self.playerNum) .. "_" .. tostring(partIndex)
    
    if not stiffness or stiffness <= 0 then
        -- Stiffness is 0, clear expected value
        expectedStiffness[partKey] = nil
        return nil
    end
    
    local expectedValue = expectedStiffness[partKey]
    
    local newStiffness
    if expectedValue then
        -- Continue reducing from expected value
        newStiffness = math.max(0, expectedValue - self.reductionRate)
    else
        -- First time seeing this part, start from current value
        newStiffness = math.max(0, stiffness - self.reductionRate)
    end
    
    -- Update expected value (or clear if it reached 0)
    if newStiffness <= 0 then
        expectedStiffness[partKey] = nil
    else
        expectedStiffness[partKey] = newStiffness
    end
    
    -- Check if current value matches expected (within tolerance)
    if math.abs(stiffness - newStiffness) > self.tolerance then
        -- Value doesn't match - enforce our expected value
        bodyPart:setStiffness(newStiffness)
        self.bodyPartsModified = true
        return newStiffness
    end
    
    return newStiffness
end

function BedStiffnessAction:syncBodyDamage(bodyDamage)
    if self.bodyPartsModified and isServer() then
        if bodyDamage and bodyDamage.Update then
            bodyDamage:Update()
        end
    end
end



-- Bed resting stiffness handler
-- Guard to prevent overwriting if loaded multiple times
bedRestingStiffness = bedRestingStiffness or {}
bedRestingStiffness.__index = bedRestingStiffness

--- Creates a new bed resting stiffness handler and processes stiffness reduction
--- @param character IsoPlayer The player character object
--- @return table|nil The stiffness handler instance, or nil if not resting on bed
function bedRestingStiffness:new(character)
    if not character then
        return nil
    end
    
    -- Check if player is resting on a bed
    local restType = BetterResting.detectRestType(character)
    if restType ~= BetterResting.RestType.BED then
        return nil  -- Not resting on bed, don't process
    end
    
    -- Create instance
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.character = character
    o.bodyPartsModified = false
    
    -- Process stiffness reduction
    local bodyDamage = character:getBodyDamage()
    if not bodyDamage then
        return nil
    end
    
    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local bodyPart = bodyParts:get(i)
            if bodyPart and bodyPart.getStiffness and bodyPart.setStiffness then
                local stiffness = bodyPart:getStiffness()
                if stiffness and stiffness > 0 then
                    -- Calculate reduction per tick
                    local reduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
                    local newStiffness = math.max(0, stiffness - reduction)
                    
                    -- setStiffness doesn't return a value - it's a void function
                    bodyPart:setStiffness(newStiffness)
                    o.bodyPartsModified = true
                end
            end
        end
        
        -- Sync body damage changes (server-side)
        -- bodyDamage:Update() should handle syncing to clients
        if o.bodyPartsModified and isServer() then
            if bodyDamage.Update then
                bodyDamage:Update()
            end
        end
    end
    
    return o
end

-- Client-side: Send command to server when resting on bed
-- NOTE: Only in multiplayer - in single player, server processes directly via OnPlayerUpdate
if isClient() and not isServer() then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then return end
        
        local restType = BetterResting.detectRestType(player)
        if restType == BetterResting.RestType.BED then
            sendClientCommand(player, "BetterResting", "ReduceStiffness", {})
        end
    end)
end