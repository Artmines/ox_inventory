-- mythic ox bridge : item converter
-- loads all mythic items via the index aggregator and registers them with ox
-- Items.new doesn't exist in ox — we get the ItemList directly via Items() and set on it

local Items    = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local ItemList = Items() -- returns the full ItemList table

local function ConvertItem(item)
    if not item.name then return nil end

    local data = {
        name        = item.name,
        label       = item.label,
        description = item.description or nil,
        weight      = item.weight or 0,
        stack       = item.isStackable ~= false and (item.isStackable or true),
        close       = item.closeUi or false,
        decay       = item.isDestroyed or false,
        degrade     = item.durability and math.floor(item.durability / 60) or nil,
        server      = {
            mythicType   = item.type,
            mythicRarity = item.rarity,
            state        = item.state,
            isRemoved    = item.isRemoved or false,
            animConfig = item.animConfig or nil,
        },
    }

    if item.type == 2 and item.weapon then
        data.weapon = true
        data.model  = item.weapon
    end

    if item.type == 9 then
        data.ammo  = true
        data.stack = true
    end
    -- auto-set durability flag for degrading items
    if not data.durability then
        if data.degrade or (data.consume and data.consume ~= 0 and data.consume < 1) then
            data.durability = true
        end
    end
    -- server side doesnt need client data
    data.client = nil
    return data
end

local function registerConsumableUse(item)
    Inventory.Items:RegisterUse(item.name, 'StatusConsumable', function(source, slotData)
    -- use direct ox export so the numeric source hits the in memory player inventory
    -- going through remove slot stringifies the source and thats no bueno :)
        exports['ox_inventory']:RemoveItem(source, slotData.Name, 1, nil, slotData.Slot)

        if item.statusChange then
            if item.statusChange.Add then
                for k,  v in pairs(item.statusChange.Add) do
                    TriggerClientEvent('Status:Client:updateStatus', source, k, true, v)
                end
            end
            if item.statusChange.Remove then
                for k, v in pairs(item.statusChange.Remove) do
                    TriggerClientEvent('Status:Client:updateStatus', source, k, false, -v)
                end
            end
            if item.statusChange.Ignore then
                for k, v in pairs(item.statusChange.Ignore) do
                    Player(source).state[('ignore%s'):format(k)] = v
                end
            end
        end

        if item.healthModifier then TriggerClientEvent('Inventory:Client:HealthModifier', source, item.healthModifier) end
        if item.armourModifier then TriggerClientEvent('Inventory:Client:ArmourModifier', source, item.armourModifier) end
        if item.stressTicks then Player(source).state.stressTicks = item.stressTicks end
        if item.energyModifier then
            TriggerClientEvent('Inventory:Client:SpeedyBoi', source,
            item.energyModifier.modifier,
            item.energyModifier.duration * 1000,
            item.energyModifier.cooldown * 1000,
            item.energyModifier.skipScreenEffects)
        end
        if item.progressModifier then
            TriggerClientEvent('Execute:Client:Component', source, 'Progress', 'Modifier',
            item.progressModifier.modifier,
            math.random(item.progressModifier.min, item.progressModifier.max) * 60000)
        end
    end)
end

local allItems = lib.load('data.mythic-items.index')
if not allItems then
    print('^1[mythic-ox-bridge] failed to load item index^0')
    return
end
local itemCount, callbackCount = 0, 0

for _, item in ipairs(allItems) do
    local converted = ConvertItem(item)
    if converted then
        ItemList[item.name] = converted
        itemCount = itemCount + 1
    end
    if item.type == 1 and (item.statusChange or item.healthModifier or item.armourModifier or item.stressTicks or item.energyModifier) then
        registerConsumableUse(item)
        callbackCount = callbackCount + 1
    end
end

print(string.format('^2[mythic-ox-bridge] loaded %d items, %d consumable callbacks :)^0', itemCount, callbackCount))