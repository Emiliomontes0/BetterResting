-- BetterResting Shared Script
-- Configuration accessible by both client and server

BetterResting = BetterResting or {}
BetterResting.Version = "1.0"
BetterResting.ModID = "BetterResting"

-- Configuration values
BetterResting.Config = {
    -- Chair/Sofa bonuses
    ChairStaminaRegenMultiplier = 1.5,        -- 50% faster stamina regen on chairs
    ChairBuffDuration = 600,                  -- 10 minutes = 600 seconds (game time)
    ChairStaminaConsumptionReduction = 0.75,  -- 25% reduction when buff active
    MinChairRestTime = 0.1,
    MinBuffDuration = 0.1,
    MaxBuffDuration = 1.0,
    
    -- Vehicle bonuses
    VehicleStaminaRegenMultiplier = 2.0,      -- 2x faster stamina regen in vehicle
    VehicleStaminaConsumptionReduction = 0.5, -- 50% reduction while in vehicle
    
    -- Bed bonuses
    BedStaminaRegenMultiplier = 3.0,
    BedHPRegenMultiplier = 1.3,               -- 30% faster HP regen
    BedMuscleFatigueReduction = 0.15,         -- 15% faster muscle fatigue recovery per hour

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
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            local spriteName = obj:getSprite():getName():lower()
            
            -- Check for beds
            if spriteName:find("bed") or 
               spriteName:find("furniture_bed") or
               spriteName:find("furniture_sleeping") then
                return BetterResting.RestType.BED
            end
            
            -- Check for chairs/sofas/couches
            if spriteName:find("chair") or 
               spriteName:find("sofa") or 
               spriteName:find("couch") or
               spriteName:find("seat") or
               spriteName:find("furniture_seating") then
                return BetterResting.RestType.CHAIR
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