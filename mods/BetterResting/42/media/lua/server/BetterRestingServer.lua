if not BetterResting then
    require "BetterRestingShared"
end

BetterResting.Server = BetterResting.Server or {}

BetterResting.Server.playerRestData = {}

BetterResting.Server.updateCounter = 0

BetterResting.Server.Commands = {}
BetterResting.Server.Commands.BetterResting = {}

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
            chairRestStartStamina = 1.0,
            lastRestType = nil,
        }
    end
    if not self.playerRestData[playerNum].lastStaminaLevel then
        local stats = player:getStats()
        if stats then
            local stamina = stats:get(CharacterStat.ENDURANCE)
            if stamina then
                self.playerRestData[playerNum].lastStaminaLevel = stamina
            end
        end
    end
    return self.playerRestData[playerNum]
end

function BetterResting.Server:applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina >= 0.99 and not data.wasFullStamina then
        if data.chairRestStartStamina and data.chairRestStartStamina < 0.75 then
            -- ChairBuffDuration is in seconds (real time), convert to minutes
            local BuffDurationMinutes = BetterResting.Config.ChairBuffDuration / 60.0

            data.chairBuffActive = true
            
            local calendar = Calendar.getInstance()
            local currentTimeMinutes = 0
            if calendar then
                -- Real time in minutes (not game time)
                currentTimeMinutes = calendar:getTimeInMillis() / (1000 * 60)
            else
                currentTimeMinutes = BetterResting.getCurrentGameHours() * 60
            end
            
            data.chairBuffEndTime = currentTimeMinutes + BuffDurationMinutes
            
            if not BetterResting.ClientBuffData then
                BetterResting.ClientBuffData = {}
            end
            BetterResting.ClientBuffData.chairBuffEndTime = data.chairBuffEndTime
            BetterResting.ClientBuffData.chairBuffActive = true

            data.chairRestStartTime = 0
            data.chairRestStartStamina = 1.0
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
    
    if stamina < 1.0 then
        local baseRegen = 0.001 
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
    
    self:applyChairBuff(player, data)
end

function BetterResting.Server:processVehicleResting(player, data, updateCounter)
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

function BetterResting.Server.Commands.BetterResting.ReduceStiffness(module, command, player, args)
    bedRestingStiffness:new(player)
end

function BetterResting.Server.Commands.BetterResting.HealWounds(module, command, player, args)
    bedWoundHealing:new(player)
end

function BetterResting.Server.Commands.BetterResting.ProcessChairResting(module, command, player, args)
    if not player then return end
    local data = BetterResting.Server:initPlayerData(player)
    BetterResting.Server:processChairResting(player, data, 0)
end

function BetterResting.Server.Commands.BetterResting.ProcessVehicleResting(module, command, player, args)
    if not player then return end
    local data = BetterResting.Server:initPlayerData(player)
    BetterResting.Server:processVehicleResting(player, data, 0)
end

function BetterResting.Server.Commands.BetterResting.ProcessBedResting(module, command, player, args)
    if not player then return end
    local data = BetterResting.Server:initPlayerData(player)
    BetterResting.Server:processBedStaminaRegen(player, data, 0)
end

function BetterResting.Server:processBedRestingStiffness(player, updateCounter)
    bedRestingStiffness:new(player)
end

function BetterResting.Server:processBedStaminaRegen(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    -- Process stamina regen (similar to chair/vehicle)
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if stamina and stamina < 1.0 then
        local baseRegen = 0.001 
        local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

function BetterResting.Server:processBedResting(player, data, updateCounter)
    -- Process stamina regen (similar to chair/vehicle)
    self:processBedStaminaRegen(player, data, updateCounter)
    
    -- Process wound healing (reduce wound timers)
    bedWoundHealing:new(player)
    
    -- Process muscle fatigue reduction (stiffness)
    self:processBedRestingStiffness(player, updateCounter)
end

function BetterResting.Server:cleanupExpiredBuffs(player, data)
    if data.chairBuffActive then
        local calendar = Calendar.getInstance()
        local currentTimeMinutes = 0
        if calendar then
            currentTimeMinutes = calendar:getTimeInMillis() / (1000 * 60)
        else
            currentTimeMinutes = BetterResting.getCurrentGameHours() * 60
        end
        
        if currentTimeMinutes >= data.chairBuffEndTime then
            data.chairBuffActive = false
            if BetterResting.ClientBuffData then
                BetterResting.ClientBuffData.chairBuffActive = false
                BetterResting.ClientBuffData.chairBuffEndTime = 0
            end
        end
    end
end

function BetterResting.Server:applyChairBuffEffect(player, data)
    if not data.chairBuffActive then
        return
    end
    
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if data.lastStaminaLevel and stamina < data.lastStaminaLevel then
        local staminaLost = data.lastStaminaLevel - stamina
        local refund = staminaLost * (1.0 - BetterResting.Config.ChairStaminaConsumptionReduction)
        if refund > 0 then
            local newStamina = math.min(1.0, stamina + refund)
            stats:set(CharacterStat.ENDURANCE, newStamina)
            data.lastStaminaLevel = newStamina
            return
        end
    end
    
    data.lastStaminaLevel = stamina
end

function BetterResting.Server:onPlayerUpdate(player)
    if not player then 
        return
    end
    
    self.updateCounter = self.updateCounter + 1
    local updateCounter = self.updateCounter
    
    local data = self:initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

    if data.lastRestType ~= restType then
        if restType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = BetterResting.getCurrentGameHours()
            local stats = player:getStats()
            if stats then
                local stamina = stats:get(CharacterStat.ENDURANCE)
                if stamina then
                    data.chairRestStartStamina = stamina
                end
            end
        elseif data.lastRestType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = 0
            data.chairRestStartStamina = 1.0
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
        self:processBedResting(player, data, updateCounter)
    end
    
    self:applyChairBuffEffect(player, data)
    
    self:cleanupExpiredBuffs(player, data)
end


if not isServer() and not isClient() then
    Events.OnPlayerUpdate.Add(function(player) 
        BetterResting.Server:onPlayerUpdate(player) 
    end)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if BetterResting.Server.Commands[module] and BetterResting.Server.Commands[module][command] then 
        BetterResting.Server.Commands[module][command](module, command, player, args) 
    end
end)
