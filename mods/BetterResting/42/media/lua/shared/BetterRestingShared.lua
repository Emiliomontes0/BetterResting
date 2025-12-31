BetterResting = BetterResting or {}
BetterResting.Version = "1.1"
BetterResting.ModID = "BetterResting"

BetterResting.ClientBuffData = BetterResting.ClientBuffData or {
    chairBuffActive = false,
    chairBuffEndTime = 0,
}

BetterResting.Config = {
    ChairStaminaRegenMultiplier = 1.07,
    ChairBuffDuration = 600,
    ChairStaminaConsumptionReduction = 0.75,
    MinChairRestTime = 0.1,
    MinBuffDuration = 0.1,
    MaxBuffDuration = 1.0,
    
    VehicleStaminaRegenMultiplier = 1.10,
    VehicleStaminaConsumptionReduction = 0.5,
    
    BedStaminaRegenMultiplier = 1.2,
    BedHPRegenMultiplier = 2.0,
    BedMuscleFatigueReduction = 0.30,
    BedWoundHealingMultiplier = 2.0,
}

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

function BetterResting.getCurrentGameHours()
    if not gameTime then
        return 0 
    end
    
    local calendar = Calendar.getInstance()
    if calendar then
        local timeInMillis = calendar:getTimeInMillis()
        return timeInMillis / (1000 * 60)
    end
    
    return gameTime:getMultiplier()
end

function BetterResting.isPlayerResting(player)
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
                    end
                end
            end
            
            if bed and not isActuallyBed then
                bed = nil
            end
        end
    end
            
    if bed then
        return BetterResting.RestType.BED
    end
    
    return nil  
end

function BetterResting.isActuallyChair(player)
    local isSittingOnFurniture = false
    if player.isSittingOnFurniture then
        isSittingOnFurniture = player:isSittingOnFurniture()
    end
    
    if isSittingOnFurniture then
        local furnitureObj = nil
        if player.getSitOnFurnitureObject then
            furnitureObj = player:getSitOnFurnitureObject()
            
            if furnitureObj then
                local isSeatingFurniture = false
                local isBedObject = false
                
                if furnitureObj.getSprite then
                    local sprite = furnitureObj:getSprite()
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
                                isSeatingFurniture = true
                            elseif spriteNameLower:find("bed") or 
                                   spriteNameLower:find("bedding") or 
                                   spriteNameLower:find("sleeping") then
                                isBedObject = true
                            end
                        end
                    end
                end
                
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
                            end
                        end
                    end
                end
                
                if not isSeatingFurniture and not isBedObject then
                    if furnitureObj.getProperties then
                        local props = furnitureObj:getProperties()
                        if props then
                            if props:get("bed") or props:get("BedType") then
                                isBedObject = true
                            end
                        end
                    end
                    if furnitureObj.bed or furnitureObj.BedType then
                        isBedObject = true
                    end
                end
                
                if isBedObject then
                    return BetterResting.RestType.BED
                end
            end
        end
        
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

function BetterResting.detectRestType(player)
    local isActuallyResting = BetterResting.isPlayerResting(player)

    if BetterResting.isActuallyVehicle(player) == BetterResting.RestType.VEHICLE then
        return BetterResting.RestType.VEHICLE
    end

    if player.currentSpeed and player.currentSpeed > 0.0 then
        return BetterResting.RestType.NOT_RESTING
    end

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

        if player:isSitOnGround() then
            return BetterResting.RestType.FLOOR
        end
    end

    local tileResult = BetterResting.tileCheck(player)
    if tileResult then
        return tileResult
    end

    if not isActuallyResting then
        return BetterResting.RestType.NOT_RESTING
    end

    return BetterResting.RestType.NOT_RESTING
end

bedRestingStiffness = bedRestingStiffness or {}
bedRestingStiffness.__index = bedRestingStiffness

function bedRestingStiffness:new(character)
    if not character then
        return nil
    end
    
    local restType = BetterResting.detectRestType(character)
    if restType ~= BetterResting.RestType.BED then
        return nil  
    end
    
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.character = character
    o.bodyPartsModified = false
    
    local bodyDamage = character:getBodyDamage()
    if not bodyDamage then
        return nil
    end
    
    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local bodyPart = bodyParts:get(i)
            if bodyPart then
                if bodyPart.getStiffness and bodyPart.setStiffness then
                    local stiffness = bodyPart:getStiffness()
                    if stiffness and stiffness > 0 then
                        local reduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
                        local newStiffness = math.max(0, stiffness - reduction)
                        
                        bodyPart:setStiffness(newStiffness)
                        o.bodyPartsModified = true
                    end
                end
                
                local baseReductionPerTick = 0.001 * (BetterResting.Config.BedWoundHealingMultiplier - 1.0)
                
                local function reduceWoundTime(getFunc, setFunc)
                    if getFunc and setFunc then
                        local currentTime = getFunc(bodyPart)
                        if currentTime and currentTime > 0 then
                            local newTime = math.max(0, currentTime - baseReductionPerTick)
                            setFunc(bodyPart, newTime)
                            if newTime ~= currentTime then
                                o.bodyPartsModified = true
                            end
                        end
                    end
                end
                
                if bodyPart.getScratchTime and bodyPart.setScratchTime then
                    reduceWoundTime(bodyPart.getScratchTime, bodyPart.setScratchTime)
                end
                if bodyPart.getCutTime and bodyPart.setCutTime then
                    reduceWoundTime(bodyPart.getCutTime, bodyPart.setCutTime)
                end
                if bodyPart.getBiteTime and bodyPart.setBiteTime then
                    reduceWoundTime(bodyPart.getBiteTime, bodyPart.setBiteTime)
                end
                if bodyPart.getDeepWoundTime and bodyPart.setDeepWoundTime then
                    reduceWoundTime(bodyPart.getDeepWoundTime, bodyPart.setDeepWoundTime)
                end
                if bodyPart.getBleedingTime and bodyPart.setBleedingTime then
                    reduceWoundTime(bodyPart.getBleedingTime, bodyPart.setBleedingTime)
                end
                if bodyPart.getStitchTime and bodyPart.setStitchTime then
                    reduceWoundTime(bodyPart.getStitchTime, bodyPart.setStitchTime)
                end
                if bodyPart.getBurnTime and bodyPart.setBurnTime then
                    reduceWoundTime(bodyPart.getBurnTime, bodyPart.setBurnTime)
                end
                if bodyPart.getFractureTime and bodyPart.setFractureTime then
                    reduceWoundTime(bodyPart.getFractureTime, bodyPart.setFractureTime)
                end
            end
        end
        
        if o.bodyPartsModified and isServer() then
            if bodyDamage.Update then
                bodyDamage:Update()
            end
        end
    end
    
    return o
end

if isClient() and not isServer() then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then return end
        
        local restType = BetterResting.detectRestType(player)
        if restType == BetterResting.RestType.BED then
            sendClientCommand(player, "BetterResting", "ReduceStiffness", {})
        elseif restType == BetterResting.RestType.CHAIR then
            sendClientCommand(player, "BetterResting", "ProcessChairResting", {})
        elseif restType == BetterResting.RestType.VEHICLE then
            sendClientCommand(player, "BetterResting", "ProcessVehicleResting", {})
        end
    end)
end
