-- BetterResting Server-side Script
-- Handles game mechanics (stamina, healing, buffs) - authoritative in multiplayer
-- In single-player, this runs alongside client script

-- Shared script should auto-load, but require as fallback
if not BetterResting then
    require "BetterRestingShared"
end

-- -------------------------------------------------------------------------- --
--                                   Data                                     --
-- -------------------------------------------------------------------------- --
BetterResting.Server = BetterResting.Server or {}

-- Track player states (game mechanics) - server authoritative
BetterResting.Server.playerRestData = {}

-- Track expected stiffness values per body part to prevent client overwrites
-- Key: "playerNum_partIndex" -> expected stiffness value
BetterResting.Server.expectedStiffness = {}

-- Track expected pain values per body part to prevent stiffness regeneration
-- Key: "playerNum_partIndex" -> expected pain value
BetterResting.Server.expectedPain = {}

-- Track expected character-level pain to prevent it from being recalculated from body parts
-- Key: "playerNum" -> expected character-level pain value
BetterResting.Server.expectedCharacterPain = {}

BetterResting.Server.updateCounter = 0

-- Commands structure (similar to FasterResting mod pattern)
BetterResting.Server.Commands = {}
BetterResting.Server.Commands.BetterResting = {}

-- -------------------------------------------------------------------------- --
--                                  Methods                                   --
-- -------------------------------------------------------------------------- --
function BetterResting.Server:initPlayerData(player)
    local playerNum = player:getPlayerNum()
    if not self.playerRestData[playerNum] then
        self.playerRestData[playerNum] = {
            currentRestType = nil,
            chairBuffActive = false,
            chairBuffEndTime = 0,
            lastStaminaLevel = 1.0,
            wasFullStamina = false,
            chairRestStartTime = 0,
            lastRestType = nil,
        }
    end
    return self.playerRestData[playerNum]
end

function BetterResting.Server:applyChairBuff(player, data)
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

function BetterResting.Server:processChairResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    -- Enhanced stamina regen while resting on chair
    if stamina < 1.0 then
        local baseRegen = 0.001 -- Base stamina regen per tick
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
    
    -- Check and apply buff when stamina is full
    self:applyChairBuff(player, data)
end

function BetterResting.Server:processVehicleResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    -- Enhanced stamina regen while in vehicle
    if stamina < 1.0 then
        local baseRegen = 0.001 -- Base stamina regen per tick
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

-- Command handler for stiffness reduction (following FasterResting pattern)
-- TESTING MODE: Simple stiffness reduction without pain or enforcement
function BetterResting.Server.Commands.BetterResting.ReduceStiffness(module, command, player, args)
    -- Use the bedRestingStiffness:new() function to process stiffness
    -- It already includes bed check and stiffness reduction logic
    bedRestingStiffness:new(player)
end

-- Process bed resting stiffness (wrapper that calls bedRestingStiffness function)
function BetterResting.Server:processBedRestingStiffness(player, updateCounter)
    -- Use the bedRestingStiffness:new() function - it includes bed check and processing
    bedRestingStiffness:new(player)
end


function BetterResting.Server:cleanupExpiredBuffs(player, data)
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
end

-- -------------------------------------------------------------------------- --
--                                  Handlers                                  --
-- -------------------------------------------------------------------------- --
function BetterResting.Server:onPlayerUpdate(player)
    if not player then 
        return
    end
    
    self.updateCounter = self.updateCounter + 1
    local updateCounter = self.updateCounter
    
    -- Initialize player data
    local data = self:initPlayerData(player)
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
    
    if restType == BetterResting.RestType.CHAIR then
        self:processChairResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.VEHICLE then
        self:processVehicleResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.BED then
        self:processBedRestingStiffness(player, updateCounter)
    end
    
    self:cleanupExpiredBuffs(player, data)
end

-- -------------------------------------------------------------------------- --
--                                 Hook events                                --
-- -------------------------------------------------------------------------- --
Events.OnPlayerUpdate.Add(function(player) 
    BetterResting.Server:onPlayerUpdate(player) 
end)

Events.OnClientCommand.Add(function(module, command, player, args)
    if BetterResting.Server.Commands[module] and BetterResting.Server.Commands[module][command] then 
        BetterResting.Server.Commands[module][command](module, command, player, args) 
    end
end)
