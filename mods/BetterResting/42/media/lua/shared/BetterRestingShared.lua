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
    BedInjuryRegenMultiplier = 2.0,           -- Matches sandbox default; treated-injury healing assist
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
    -- Prefer SandboxVars (correct in MP). Fall back to SandboxOptions API.
    local vars = SandboxVars and SandboxVars.BetterResting or nil

    local function getOptionValue(fieldName, optionName)
        if vars and vars[fieldName] ~= nil then
            return vars[fieldName]
        end
        local sandboxOptions = SandboxOptions.getInstance and SandboxOptions.getInstance()
            or (getSandboxOptions and getSandboxOptions())
        if not sandboxOptions then
            return nil
        end
        local option = sandboxOptions:getOptionByName(optionName)
        if option then
            return option:getValue()
        end
        return nil
    end

    local chairStaminaRegen = getOptionValue("ChairStaminaRegenMultiplier", "BetterResting.ChairStaminaRegenMultiplier")
    if chairStaminaRegen then self.Config.ChairStaminaRegenMultiplier = chairStaminaRegen end

    local chairBuffDuration = getOptionValue("ChairBuffDuration", "BetterResting.ChairBuffDuration")
    if chairBuffDuration then self.Config.ChairBuffDuration = chairBuffDuration end

    local chairStaminaConsumption = getOptionValue("ChairStaminaConsumptionReduction", "BetterResting.ChairStaminaConsumptionReduction")
    if chairStaminaConsumption then self.Config.ChairStaminaConsumptionReduction = chairStaminaConsumption end

    local vehicleStaminaRegen = getOptionValue("VehicleStaminaRegenMultiplier", "BetterResting.VehicleStaminaRegenMultiplier")
    if vehicleStaminaRegen then self.Config.VehicleStaminaRegenMultiplier = vehicleStaminaRegen end

    local vehicleStaminaConsumption = getOptionValue("VehicleStaminaConsumptionReduction", "BetterResting.VehicleStaminaConsumptionReduction")
    if vehicleStaminaConsumption then self.Config.VehicleStaminaConsumptionReduction = vehicleStaminaConsumption end

    local bedStaminaRegen = getOptionValue("BedStaminaRegenMultiplier", "BetterResting.BedStaminaRegenMultiplier")
    if bedStaminaRegen then self.Config.BedStaminaRegenMultiplier = bedStaminaRegen end

    local bedInjuryRegen = getOptionValue("BedInjuryRegenMultiplier", "BetterResting.BedInjuryRegenMultiplier")
        or getOptionValue("BedHPRegenMultiplier", "BetterResting.BedHPRegenMultiplier") -- legacy key
    if bedInjuryRegen then self.Config.BedInjuryRegenMultiplier = bedInjuryRegen end

    local bedMuscleFatigue = getOptionValue("BedMuscleFatigueReduction", "BetterResting.BedMuscleFatigueReduction")
    if bedMuscleFatigue then self.Config.BedMuscleFatigueReduction = bedMuscleFatigue end

    local showMessages = getOptionValue("ShowMessages", "BetterResting.ShowMessages")
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
    if not gameTime then
        gameTime = GameTime.getInstance()
    end
    if not gameTime then
        print("BetterResting [SHARED] ERROR: GameTime.getInstance() returned nil!")
        return 0
    end
    if gameTime.getWorldAgeHours then
        return gameTime:getWorldAgeHours()
    end
    print("BetterResting [SHARED] ERROR: getWorldAgeHours() unavailable!")
    return 0
end

local function getObjectSpriteName(obj)
    if not obj or not obj.getSprite then
        return nil
    end
    local sprite = obj:getSprite()
    if not sprite or not sprite.getName then
        return nil
    end
    local spriteName = sprite:getName()
    if not spriteName then
        return nil
    end
    return tostring(spriteName)
end

local function getObjectCustomItemStr(obj)
    if not obj or not obj.getCustomItem then
        return nil
    end
    local customItem = obj:getCustomItem()
    if not customItem then
        return nil
    end
    if type(customItem) == "string" then
        return customItem
    end
    if customItem.getFullType then
        return customItem:getFullType()
    end
    if customItem.getType then
        return customItem:getType()
    end
    return nil
end

local function spriteNameLooksLikeSeating(spriteNameLower)
    return spriteNameLower:find("seating", 1, true)
        or spriteNameLower:find("chair", 1, true)
        or spriteNameLower:find("sofa", 1, true)
        or spriteNameLower:find("couch", 1, true)
        or spriteNameLower:find("stool", 1, true)
        or spriteNameLower:find("bench", 1, true)
        or spriteNameLower:find("seat", 1, true)
end

local function spriteNameLooksLikeBed(spriteNameLower)
    return spriteNameLower:find("bed", 1, true)
        or spriteNameLower:find("bedding", 1, true)
        or spriteNameLower:find("sleeping", 1, true)
        or spriteNameLower:find("tent", 1, true)
        or spriteNameLower:find("cot", 1, true)
        or spriteNameLower:find("gurney", 1, true)
        or spriteNameLower:find("camping_", 1, true)
end

local function objectHasBedProperty(obj)
    if obj.getProperties then
        local props = obj:getProperties()
        if props and (props:get("bed") or props:get("BedType")) then
            return true
        end
    end
    if obj.bed or obj.BedType then
        return true
    end
    return false
end

-- True when the player is in a rest/sit state (not merely standing on a furniture tile).
-- In B42, isResting() is often only true briefly while entering a bed/chair; settled
-- sit/lie states use isSittingOnFurniture() / getBed() instead.
function BetterResting.isPlayerResting(player)
    if not player then
        return false
    end
    if player.isResting and player:isResting() then
        return true
    end
    if player.isSittingOnFurniture and player:isSittingOnFurniture() then
        return true
    end
    if player.getBed and player:getBed() then
        return true
    end
    if player.isSitOnGround and player:isSitOnGround() then
        return true
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
    if not player or not player.getBed then
        return nil
    end

    local bed = player:getBed()
    if not bed then
        return nil
    end

    local spriteName = getObjectSpriteName(bed)
    if spriteName then
        local spriteNameLower = spriteName:lower()

        -- getBed() can briefly point at seating; reject clear chairs/sofas
        if spriteNameLooksLikeSeating(spriteNameLower) and not spriteNameLooksLikeBed(spriteNameLower) then
            return nil
        end

        if BetterResting.BedSprites and BetterResting.BedSprites[spriteName] then
            return BetterResting.RestType.BED
        end
        if spriteNameLooksLikeBed(spriteNameLower) then
            return BetterResting.RestType.BED
        end
    end

    local customItemStr = getObjectCustomItemStr(bed)
    if customItemStr and BetterResting.BedCustomItems and BetterResting.BedCustomItems[customItemStr] then
        return BetterResting.RestType.BED
    end

    if objectHasBedProperty(bed) then
        return BetterResting.RestType.BED
    end

    -- Trust getBed() when we cannot positively identify seating
    return BetterResting.RestType.BED
end

function BetterResting.isActuallyChair(player)
    if not player or not player.isSittingOnFurniture or not player:isSittingOnFurniture() then
        return nil
    end

    local furnitureObj = nil
    if player.getSitOnFurnitureObject then
        furnitureObj = player:getSitOnFurnitureObject()
    end

    if furnitureObj then
        local spriteName = getObjectSpriteName(furnitureObj)
        if spriteName then
            local spriteNameLower = spriteName:lower()

            if BetterResting.BedSprites and BetterResting.BedSprites[spriteName] then
                return BetterResting.RestType.BED
            end
            if BetterResting.ChairSprites and BetterResting.ChairSprites[spriteName] then
                return BetterResting.RestType.CHAIR
            end
            if spriteNameLooksLikeBed(spriteNameLower) then
                return BetterResting.RestType.BED
            end
            if spriteNameLooksLikeSeating(spriteNameLower) then
                return BetterResting.RestType.CHAIR
            end
        end

        local customItemStr = getObjectCustomItemStr(furnitureObj)
        if customItemStr and BetterResting.BedCustomItems and BetterResting.BedCustomItems[customItemStr] then
            return BetterResting.RestType.BED
        end

        if objectHasBedProperty(furnitureObj) then
            return BetterResting.RestType.BED
        end
    end

    return BetterResting.RestType.CHAIR
end

function BetterResting.tileCheck(player)
    if not player then return nil end

    local square = player:getCurrentSquare()
    if not square then return nil end

    local objects = square:getObjects()
    if not objects then return nil end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local spriteName = getObjectSpriteName(obj)
        if spriteName then
            local restType = BetterResting.getRestTypeFromSprite(spriteName)
            if restType then
                return restType
            end
        end
    end

    return nil
end

function BetterResting.detectRestType(player)
    if not player then
        return BetterResting.RestType.NOT_RESTING
    end

    if BetterResting.isActuallyVehicle(player) == BetterResting.RestType.VEHICLE then
        return BetterResting.RestType.VEHICLE
    end

    if player.currentSpeed and player.currentSpeed > 0.0 then
        return BetterResting.RestType.NOT_RESTING
    end

    -- Prefer furniture/bed APIs first. These stay true after sit/lie settles,
    -- while isResting() often only covers the enter animation (~1-2s).
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

    -- Sprite / ground fallback only while in a real rest/sit state
    -- (avoids standing-on-tile false positives)
    if not BetterResting.isPlayerResting(player) then
        return BetterResting.RestType.NOT_RESTING
    end

    local tileResult = BetterResting.tileCheck(player)
    if tileResult then
        return tileResult
    end

    if player.isSitOnGround and player:isSitOnGround() then
        return BetterResting.RestType.FLOOR
    end

    return BetterResting.RestType.NOT_RESTING
end

bedRestingStiffness = bedRestingStiffness or {}
bedRestingStiffness.__index = bedRestingStiffness

--- @param character IsoPlayer The player character object
--- @param forceBed boolean|nil If true, skip detectRestType (server already resolved bed rest)
--- @return table|nil The stiffness handler instance, or nil if not resting on bed
function bedRestingStiffness:new(character, forceBed)
    if not character then
        return nil
    end
    
    if not forceBed then
        local restType = BetterResting.detectRestType(character)
        if restType ~= BetterResting.RestType.BED then
            return nil  
        end
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
        
        if o.bodyPartsModified and (isServer() or not isClient()) then
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
--- @param forceBed boolean|nil If true, skip detectRestType (server already resolved bed rest)
--- @return table|nil The wound healing handler instance, or nil if not resting on bed
function bedWoundHealing:new(character, forceBed)
    if not character then
        return nil
    end
    
    if not forceBed then
        local restType = BetterResting.detectRestType(character)
        if restType ~= BetterResting.RestType.BED then
            return nil  
        end
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
        local reduction = 0.001 * BetterResting.Config.BedInjuryRegenMultiplier
        
        -- Use same loop structure as old code (1 to size, get(i-1))
        for i = 1, bodyParts:size() do
            local bodyPart = bodyParts:get(i - 1)
            if bodyPart then
                -- Only heal wounds if they are bandaged or stitched (treated wounds)
                local isTreated = false
                if bodyPart.bandaged and bodyPart:bandaged() then
                    isTreated = true
                elseif bodyPart.stitched and bodyPart:stitched() then
                    isTreated = true
                end
                
                -- Reduce scratch healing time (only if treated)
                if isTreated and bodyPart.getScratchTime and bodyPart.setScratchTime and bodyPart.setScratched then
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
                
                -- Reduce cut healing time (only if treated)
                if isTreated and bodyPart.getCutTime and bodyPart.setCutTime and bodyPart.setCut then
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
                
                -- Reduce deep wound healing time (only if treated)
                if isTreated and bodyPart.getDeepWoundTime and bodyPart.setDeepWoundTime and bodyPart.setDeepWounded then
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
                
                -- Reduce bleeding time (only if bleeding is stemmed/cauterized/treated)
                local isBleedingTreated = false
                if bodyPart.IsBleedingStemmed and bodyPart:IsBleedingStemmed() then
                    isBleedingTreated = true
                elseif bodyPart.IsCauterized and bodyPart:IsCauterized() then
                    isBleedingTreated = true
                elseif isTreated then
                    -- If wound is bandaged/stitched, bleeding should be treated
                    isBleedingTreated = true
                end
                
                if isBleedingTreated and bodyPart.getBleedingTime and bodyPart.setBleedingTime then
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
                -- Reduce burn healing time (only if treated/bandaged)
                if isTreated and bodyPart.getBurnTime and bodyPart.setBurnTime then
                    local burnTime = bodyPart:getBurnTime()
                    if burnTime and burnTime > 0 then
                        local newTime = math.max(0, burnTime - reduction)
                        bodyPart:setBurnTime(newTime)
                        o.bodyPartsModified = true
                    end
                end
            end
        end
        
        if o.bodyPartsModified and (isServer() or not isClient()) then
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

-- Mechanics:
-- SP: server OnPlayerUpdate detects + applies
-- MP: client detects, sendClientCommand Process*; server applies + syncPlayerStats
-- Sandbox: prefer SandboxVars.BetterResting.* (required for MP config)