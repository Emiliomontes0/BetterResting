-- BetterResting Shared Script
-- Configuration accessible by both client and server

BetterResting = BetterResting or {}
BetterResting.Version = "1.1"
BetterResting.ModID = "BetterResting"
BetterResting.ModName = "BetterResting"

-- Configuration values
BetterResting.Config = {
    -- Chair/Sofa bonuses
    ChairStaminaRegenMultiplier = 1.07,       -- 7% faster stamina regen on chairs
    ChairBuffDuration = 600,                  -- 10 minutes = 600 seconds (real time, not game time)
    ChairStaminaConsumptionReduction = 0.75,  -- 25% reduction when buff active
    
    -- Vehicle bonuses
    VehicleStaminaRegenMultiplier = 1.10,     -- 10% faster stamina regen in vehicle
    VehicleStaminaConsumptionReduction = 0.5, -- 50% reduction while in vehicle
    
    -- Bed bonuses
    BedStaminaRegenMultiplier = 1.2,          -- 20% faster stamina regen in bed
    BedHPRegenMultiplier = 6.0,               -- 2x faster HP regen (gradual healing)
    BedMuscleFatigueReduction = 0.30,         -- 30% faster muscle fatigue recovery (increased from 15%)
    
    -- UI settings
    ShowMessages = true,                      -- Show all messages above player (rest type, buffs, etc.)

}

-- Rest location types
BetterResting.RestType = {
    FLOOR = "floor",
    CHAIR = "chair",
    VEHICLE = "vehicle",
    BED = "bed",
    NOT_RESTING = "not_resting"
}

function BetterResting:buildOptions()
    -- Sandbox options are now defined in sandbox-options.txt
    -- This function is kept for compatibility but no longer needed
end

function BetterResting:syncOptions()
    local sandboxOptions = SandboxOptions.getInstance()
    if not sandboxOptions then
        return
    end
    
    -- Helper function to safely get option value
    local function getOptionValue(optionName)
        local option = sandboxOptions:getOptionByName(optionName)
        if option then
            return option:getValue()
        end
        return nil
    end
    
    -- Chair/Sofa bonuses
    local chairStaminaRegen = getOptionValue("BetterResting.ChairStaminaRegenMultiplier")
    if chairStaminaRegen then self.Config.ChairStaminaRegenMultiplier = chairStaminaRegen end
    
    local chairBuffDuration = getOptionValue("BetterResting.ChairBuffDuration")
    if chairBuffDuration then self.Config.ChairBuffDuration = chairBuffDuration end
    
    local chairStaminaConsumption = getOptionValue("BetterResting.ChairStaminaConsumptionReduction")
    if chairStaminaConsumption then self.Config.ChairStaminaConsumptionReduction = chairStaminaConsumption end
    
    -- Vehicle bonuses
    local vehicleStaminaRegen = getOptionValue("BetterResting.VehicleStaminaRegenMultiplier")
    if vehicleStaminaRegen then self.Config.VehicleStaminaRegenMultiplier = vehicleStaminaRegen end
    
    local vehicleStaminaConsumption = getOptionValue("BetterResting.VehicleStaminaConsumptionReduction")
    if vehicleStaminaConsumption then self.Config.VehicleStaminaConsumptionReduction = vehicleStaminaConsumption end
    
    -- Bed bonuses
    local bedStaminaRegen = getOptionValue("BetterResting.BedStaminaRegenMultiplier")
    if bedStaminaRegen then self.Config.BedStaminaRegenMultiplier = bedStaminaRegen end
    
    local bedHPRegen = getOptionValue("BetterResting.BedHPRegenMultiplier")
    if bedHPRegen then self.Config.BedHPRegenMultiplier = bedHPRegen end
    
    local bedMuscleFatigue = getOptionValue("BetterResting.BedMuscleFatigueReduction")
    if bedMuscleFatigue then self.Config.BedMuscleFatigueReduction = bedMuscleFatigue end
    
    -- UI settings (boolean)
    local showMessages = getOptionValue("BetterResting.ShowMessages")
    if showMessages ~= nil then self.Config.ShowMessages = showMessages end
end

function BetterResting:OnGameBoot()
    self:buildOptions()
end

function BetterResting:onTick()
    self:syncOptions()
end

local gameTime
Events.OnGameTimeLoaded.Add(function()
    gameTime = GameTime.getInstance()
end)

function BetterResting.getCurrentGameHours()
    if not gameTime then --checker incase api changes
        print("BetterResting [SHARED] ERROR: getGameTime() returned nil!")
        return 0 
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
                    else

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
    else
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

    --first check Method
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

        if player.isSitOnGround() then
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
        expectedStiffness[partKey] = nil
        return nil
    end
    
    local expectedValue = expectedStiffness[partKey]
    
    local newStiffness
    if expectedValue then
        newStiffness = math.max(0, expectedValue - self.reductionRate)
    else
        newStiffness = math.max(0, stiffness - self.reductionRate)
    end
    
    if newStiffness <= 0 then
        expectedStiffness[partKey] = nil
    else
        expectedStiffness[partKey] = newStiffness
    end
    
    if math.abs(stiffness - newStiffness) > self.tolerance then
 
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

bedRestingStiffness = bedRestingStiffness or {}
bedRestingStiffness.__index = bedRestingStiffness

--- @param character IsoPlayer The player character object
--- @return table|nil The stiffness handler instance, or nil if not resting on bed
function bedRestingStiffness:new(character)
    if not character then
        return nil
    end
    
    local restType = BetterResting.detectRestType(character)
    if restType ~= BetterResting.RestType.BED then
        return nil  
    end
    
    -- Create instance
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
            if bodyPart and bodyPart.getStiffness and bodyPart.setStiffness then
                local stiffness = bodyPart:getStiffness()
                if stiffness and stiffness > 0 then
                    local reduction = 0.002 * BetterResting.Config.BedMuscleFatigueReduction * 100
                    local newStiffness = math.max(0, stiffness - reduction)
                    
                    bodyPart:setStiffness(newStiffness)
                    o.bodyPartsModified = true
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

bedWoundHealing = bedWoundHealing or {}
bedWoundHealing.__index = bedWoundHealing

--- @param character IsoPlayer The player character object
--- @return table|nil The wound healing handler instance, or nil if not resting on bed
function bedWoundHealing:new(character)
    if not character then
        return nil
    end
    
    local restType = BetterResting.detectRestType(character)
    if restType ~= BetterResting.RestType.BED then
        return nil  
    end
    
    -- Create instance
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
        -- Base reduction rate per update (matching old working code)
        local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
        
        -- Use same loop structure as old code (1 to size, get(i-1))
        for i = 1, bodyParts:size() do
            local bodyPart = bodyParts:get(i - 1)
            if bodyPart then
                -- Reduce scratch healing time
                if bodyPart.getScratchTime and bodyPart.setScratchTime and bodyPart.setScratched then
                    local scratchTime = bodyPart:getScratchTime()
                    if scratchTime and scratchTime > 0 then
                        local newTime = math.max(0, scratchTime - reduction)
                        if newTime <= 0 then
                            bodyPart:setScratched(false, true)
                        else
                            bodyPart:setScratchTime(newTime)
                        end
                        o.bodyPartsModified = true
                    end
                end
                
                -- Reduce cut healing time
                if bodyPart.getCutTime and bodyPart.setCutTime and bodyPart.setCut then
                    local cutTime = bodyPart:getCutTime()
                    if cutTime and cutTime > 0 then
                        local newTime = math.max(0, cutTime - reduction)
                        if newTime <= 0 then
                            bodyPart:setCut(false)
                        else
                            bodyPart:setCutTime(newTime)
                        end
                        o.bodyPartsModified = true
                    end
                end
                
                -- Reduce deep wound healing time
                if bodyPart.getDeepWoundTime and bodyPart.setDeepWoundTime and bodyPart.setDeepWounded then
                    local deepWoundTime = bodyPart:getDeepWoundTime()
                    if deepWoundTime and deepWoundTime > 0 then
                        local newTime = math.max(0, deepWoundTime - reduction)
                        bodyPart:setDeepWoundTime(newTime)
                        if newTime <= 0 then
                            bodyPart:setDeepWounded(false)
                        end
                        o.bodyPartsModified = true
                    end
                end
                
                -- Reduce bleeding time
                if bodyPart.getBleedingTime and bodyPart.setBleedingTime then
                    local bleedingTime = bodyPart:getBleedingTime()
                    if bleedingTime and bleedingTime > 0 then
                        local newTime = math.max(0, bleedingTime - reduction)
                        bodyPart:setBleedingTime(newTime)
                        o.bodyPartsModified = true
                    end
                end
                
                -- Reduce stitch healing time
                if bodyPart.getStitchTime and bodyPart.setStitchTime then
                    local stitchTime = bodyPart:getStitchTime()
                    if stitchTime and stitchTime > 0 then
                        local newTime = math.max(0, stitchTime - reduction)
                        bodyPart:setStitchTime(newTime)
                        o.bodyPartsModified = true
                    end
                end
                
                -- Reduce burn healing time
                if bodyPart.getBurnTime and bodyPart.setBurnTime then
                    local burnTime = bodyPart:getBurnTime()
                    if burnTime and burnTime > 0 then
                        local newTime = math.max(0, burnTime - reduction)
                        bodyPart:setBurnTime(newTime)
                        o.bodyPartsModified = true
                    end
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

Events.OnGameBoot.Add(function()
    BetterResting:OnGameBoot()
end)
Events.OnTick.Add(function()
    BetterResting:onTick()
end)

if isClient() and not isServer() then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then return end
        
        local restType = BetterResting.detectRestType(player)
        if restType == BetterResting.RestType.BED then
            sendClientCommand(player, "BetterResting", "ProcessBedResting", {})
            sendClientCommand(player, "BetterResting", "ReduceStiffness", {})
            sendClientCommand(player, "BetterResting", "HealWounds", {})
        elseif restType == BetterResting.RestType.CHAIR then
            sendClientCommand(player, "BetterResting", "ProcessChairResting", {})
        elseif restType == BetterResting.RestType.VEHICLE then
            sendClientCommand(player, "BetterResting", "ProcessVehicleResting", {})
        end
    end)
end