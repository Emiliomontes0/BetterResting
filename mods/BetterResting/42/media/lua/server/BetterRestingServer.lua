if not BetterResting then
    require "BetterRestingShared"
end

BetterResting.Server = BetterResting.Server or {}

BetterResting.Server.playerRestData = {}
BetterResting.Server.updateCounter = 0

-- Thin legacy command table (kept for compatibility; mechanics are server-driven)
BetterResting.Server.Commands = {}
BetterResting.Server.Commands.BetterResting = {}

local function getPlayerKey(player)
    if not player then
        return nil
    end
    if player.getOnlineID then
        local onlineId = player:getOnlineID()
        if onlineId ~= nil then
            return "oid_" .. tostring(onlineId)
        end
    end
    if player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return "user_" .. username
        end
    end
    return "pnum_" .. tostring(player:getPlayerNum())
end

local function getCurrentTimeMinutes()
    local calendar = Calendar.getInstance()
    if calendar then
        return calendar:getTimeInMillis() / (1000 * 60)
    end
    return BetterResting.getCurrentGameHours() * 60
end

function BetterResting.Server:initPlayerData(player)
    local key = getPlayerKey(player)
    if not key then
        return nil
    end

    if not self.playerRestData[key] then
        self.playerRestData[key] = {
            currentRestType = nil,
            chairBuffActive = false,
            chairBuffEndTime = 0,
            lastStaminaLevel = 1.0,
            wasFullStamina = false,
            chairRestStartTime = 0,
            chairRestStartStamina = 1.0,
            lastRestType = nil,
            lastSyncedBuffActive = false,
            lastSyncedBuffEndTime = 0,
        }
    end

    local data = self.playerRestData[key]
    if not data.lastStaminaLevel then
        local stats = player:getStats()
        if stats then
            local stamina = stats:get(CharacterStat.ENDURANCE)
            if stamina then
                data.lastStaminaLevel = stamina
            end
        end
    end
    return data
end

-- Push Well Rested buff state to the owning client (or local SP UI table)
function BetterResting.Server:syncChairBuffToClient(player, data, force)
    if not player or not data then
        return
    end

    local active = data.chairBuffActive and true or false
    local endTime = data.chairBuffEndTime or 0

    if not force
        and data.lastSyncedBuffActive == active
        and data.lastSyncedBuffEndTime == endTime then
        return
    end

    data.lastSyncedBuffActive = active
    data.lastSyncedBuffEndTime = endTime

    local args = {
        active = active,
        endTime = endTime,
    }

    if isServer() then
        sendServerCommand(player, "BetterResting", "SyncChairBuff", args)
    else
        -- Singleplayer: same Lua VM, write directly for client UI
        BetterResting.ClientBuffData = BetterResting.ClientBuffData or {}
        BetterResting.ClientBuffData.chairBuffActive = active
        BetterResting.ClientBuffData.chairBuffEndTime = endTime
    end
end

function BetterResting.Server:applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end

    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end

    if stamina >= 0.99 and not data.wasFullStamina then
        if data.chairRestStartStamina and data.chairRestStartStamina < 0.75 then
            local BuffDurationMinutes = BetterResting.Config.ChairBuffDuration / 60.0

            data.chairBuffActive = true
            data.chairBuffEndTime = getCurrentTimeMinutes() + BuffDurationMinutes
            data.chairRestStartTime = 0
            data.chairRestStartStamina = 1.0

            self:syncChairBuffToClient(player, data, true)
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

function BetterResting.Server:applyVehicleStaminaReduction(player, data)
    local stats = player:getStats()
    if not stats then return end

    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end

    if data.lastStaminaLevel and stamina < data.lastStaminaLevel then
        local staminaLost = data.lastStaminaLevel - stamina
        local refund = staminaLost * (1.0 - BetterResting.Config.VehicleStaminaConsumptionReduction)
        if refund > 0 then
            local newStamina = math.min(1.0, stamina + refund)
            stats:set(CharacterStat.ENDURANCE, newStamina)
            data.lastStaminaLevel = newStamina
            return
        end
    end

    data.lastStaminaLevel = stamina
end

function BetterResting.Server:processBedRestingStiffness(player, updateCounter)
    bedRestingStiffness:new(player)
end

function BetterResting.Server:processBedStaminaRegen(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end

    local stamina = stats:get(CharacterStat.ENDURANCE)
    if stamina and stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

function BetterResting.Server:processBedResting(player, data, updateCounter)
    self:processBedStaminaRegen(player, data, updateCounter)
    bedWoundHealing:new(player)
    self:processBedRestingStiffness(player, updateCounter)
end

function BetterResting.Server:cleanupExpiredBuffs(player, data)
    if not data.chairBuffActive then
        return
    end

    if getCurrentTimeMinutes() >= data.chairBuffEndTime then
        data.chairBuffActive = false
        data.chairBuffEndTime = 0
        self:syncChairBuffToClient(player, data, true)
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
    if not data then
        return
    end

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
        self:applyVehicleStaminaReduction(player, data)
    elseif restType == BetterResting.RestType.BED then
        self:processBedResting(player, data, updateCounter)
    end

    if restType ~= BetterResting.RestType.VEHICLE then
        self:applyChairBuffEffect(player, data)
    end

    self:cleanupExpiredBuffs(player, data)
end

-- Authority loop: singleplayer OR dedicated/listen server (not pure clients)
if isServer() or not isClient() then
    Events.OnPlayerUpdate.Add(function(player)
        BetterResting.Server:onPlayerUpdate(player)
    end)
end

-- Optional: clients can request a buff resync (e.g. after reconnect)
function BetterResting.Server.Commands.BetterResting.RequestChairBuffSync(module, command, player, args)
    if not player then return end
    local data = BetterResting.Server:initPlayerData(player)
    if data then
        BetterResting.Server:syncChairBuffToClient(player, data, true)
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if BetterResting.Server.Commands[module] and BetterResting.Server.Commands[module][command] then
        BetterResting.Server.Commands[module][command](module, command, player, args)
    end
end)
