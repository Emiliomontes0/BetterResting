if not BetterResting then
    require "BetterRestingShared"
end

BetterResting.Server = BetterResting.Server or {}

BetterResting.Server.playerRestData = {}
BetterResting.Server.updateCounter = 0

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

local function getEnduranceStatId()
    if not CharacterStat then
        return nil
    end
    return CharacterStat.ENDURANCE or CharacterStat.Endurance
end

-- B42.13+ MP: server stat writes must be synced or clients keep vanilla values
local function syncEndurance(player)
    if not player or not isServer() then
        return
    end
    local statId = getEnduranceStatId()
    if syncPlayerStats and statId then
        syncPlayerStats(player, statId)
    end
end

local function readEndurance(stats)
    if not stats then
        return nil
    end
    local statId = getEnduranceStatId()
    if statId and stats.get then
        local value = stats:get(statId)
        if value ~= nil then
            return value
        end
    end
    if stats.getEndurance then
        return stats:getEndurance()
    end
    return nil
end

local function writeEndurance(player, stats, value)
    local statId = getEnduranceStatId()
    if statId and stats.set then
        stats:set(statId, value)
    elseif stats.setEndurance then
        stats:setEndurance(value)
    else
        return
    end
    syncEndurance(player)
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
        local stamina = readEndurance(stats)
        if stamina then
            data.lastStaminaLevel = stamina
        end
    end
    return data
end

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
        BetterResting.ClientBuffData = BetterResting.ClientBuffData or {}
        BetterResting.ClientBuffData.chairBuffActive = active
        BetterResting.ClientBuffData.chairBuffEndTime = endTime
    end
end

function BetterResting.Server:applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end

    local stamina = readEndurance(stats)
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

    local stamina = readEndurance(stats)
    if not stamina then return end

    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        writeEndurance(player, stats, newStamina)
    end

    self:applyChairBuff(player, data)
end

function BetterResting.Server:processVehicleResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end

    local stamina = readEndurance(stats)
    if not stamina then return end

    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        writeEndurance(player, stats, newStamina)
    end
end

function BetterResting.Server:applyVehicleStaminaReduction(player, data)
    local stats = player:getStats()
    if not stats then return end

    local stamina = readEndurance(stats)
    if not stamina then return end

    if data.lastStaminaLevel and stamina < data.lastStaminaLevel then
        local staminaLost = data.lastStaminaLevel - stamina
        local refund = staminaLost * (1.0 - BetterResting.Config.VehicleStaminaConsumptionReduction)
        if refund > 0 then
            local newStamina = math.min(1.0, stamina + refund)
            writeEndurance(player, stats, newStamina)
            data.lastStaminaLevel = newStamina
            return
        end
    end

    data.lastStaminaLevel = stamina
end

function BetterResting.Server:processBedRestingStiffness(player, updateCounter)
    bedRestingStiffness:new(player, true)
end

function BetterResting.Server:processBedStaminaRegen(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end

    local stamina = readEndurance(stats)
    if stamina and stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        writeEndurance(player, stats, newStamina)
    end
end

function BetterResting.Server:processBedResting(player, data, updateCounter)
    self:processBedStaminaRegen(player, data, updateCounter)
    bedWoundHealing:new(player, true)
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

    local stamina = readEndurance(stats)
    if not stamina then return end

    if data.lastStaminaLevel and stamina < data.lastStaminaLevel then
        local staminaLost = data.lastStaminaLevel - stamina
        local refund = staminaLost * (1.0 - BetterResting.Config.ChairStaminaConsumptionReduction)
        if refund > 0 then
            local newStamina = math.min(1.0, stamina + refund)
            writeEndurance(player, stats, newStamina)
            data.lastStaminaLevel = newStamina
            return
        end
    end

    data.lastStaminaLevel = stamina
end

-- Track chair enter/exit when rest type changes (used by both SP loop and MP commands)
function BetterResting.Server:onRestTypeChanged(player, data, restType)
    if data.lastRestType == restType then
        return
    end

    if restType == BetterResting.RestType.CHAIR then
        data.chairRestStartTime = BetterResting.getCurrentGameHours()
        local stats = player:getStats()
        local stamina = readEndurance(stats)
        if stamina then
            data.chairRestStartStamina = stamina
        end
    elseif data.lastRestType == BetterResting.RestType.CHAIR then
        data.chairRestStartTime = 0
        data.chairRestStartStamina = 1.0
        data.wasFullStamina = false
    end

    data.lastRestType = restType
    data.currentRestType = restType
end

function BetterResting.Server:applyRestType(player, restType)
    if not player then
        return
    end

    local data = self:initPlayerData(player)
    if not data then
        return
    end

    self.updateCounter = self.updateCounter + 1
    local updateCounter = self.updateCounter

    self:onRestTypeChanged(player, data, restType)

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

-- Singleplayer only: same Lua VM, detect + apply locally.
-- Multiplayer uses client commands below (furniture APIs are unreliable on dedicated).
if not isServer() and not isClient() then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then
            return
        end
        local restType = BetterResting.detectRestType(player)
        BetterResting.Server:applyRestType(player, restType)
    end)
end

-- MP: client detected chair rest → server applies bonus + syncs endurance
local didLogChair = false
function BetterResting.Server.Commands.BetterResting.ProcessChairResting(module, command, player, args)
    if not player then return end
    if not didLogChair then
        didLogChair = true
        print("BetterResting: MP chair resting active (multiplier=" ..
            tostring(BetterResting.Config.ChairStaminaRegenMultiplier) .. ")")
    end
    BetterResting.Server:applyRestType(player, BetterResting.RestType.CHAIR)
end

function BetterResting.Server.Commands.BetterResting.ProcessVehicleResting(module, command, player, args)
    if not player then return end
    BetterResting.Server:applyRestType(player, BetterResting.RestType.VEHICLE)
end

function BetterResting.Server.Commands.BetterResting.ProcessBedResting(module, command, player, args)
    if not player then return end
    BetterResting.Server:applyRestType(player, BetterResting.RestType.BED)
end

function BetterResting.Server.Commands.BetterResting.ReduceStiffness(module, command, player, args)
    if not player then return end
    bedRestingStiffness:new(player, true)
end

function BetterResting.Server.Commands.BetterResting.HealWounds(module, command, player, args)
    if not player then return end
    bedWoundHealing:new(player, true)
end

function BetterResting.Server.Commands.BetterResting.RequestChairBuffSync(module, command, player, args)
    if not player then return end
    local data = BetterResting.Server:initPlayerData(player)
    if data then
        BetterResting.Server:syncChairBuffToClient(player, data, true)
    end
end

-- MP host also needs buff expiry / consumption refund while not actively sending rest commands
if isServer() then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then
            return
        end
        local data = BetterResting.Server:initPlayerData(player)
        if not data then
            return
        end
        BetterResting.Server:applyChairBuffEffect(player, data)
        BetterResting.Server:cleanupExpiredBuffs(player, data)
    end)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if BetterResting.Server.Commands[module] and BetterResting.Server.Commands[module][command] then
        BetterResting.Server.Commands[module][command](module, command, player, args)
    end
end)
