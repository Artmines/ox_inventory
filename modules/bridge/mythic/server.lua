-- mythic ox bridge : server side
-- makes ox_inventory pretend to be mythic inventory so nothing else has to change
-- if something breaks its probably in here, good luck
--
-- REQUIRED in server.cfg or literally none of this loads:
--   set inventory:framework "mythic"

local Inventory = require 'modules.inventory.server'
local Items     = require 'modules.items.server'

local function toSource(sid)
    local player = exports['mythic-base']:FetchComponent('Fetch'):SID(tonumber(sid))
    if not player then return nil end
    return player:GetData('Source')
end

local function toTarget(owner, invType)
    invType = invType or 1
    if invType == 1 then
        return type(owner) == 'number' and toSource(owner) or owner
    elseif invType == 4 then
        return (owner:sub(1, 6) ~= 'trunk-') and 'trunk-' ..owner or owner
    elseif invType == 5 then
        return (owner:sub(1 , 6) ~= 'glove-') and 'glove-' ..owner or owner
    end
    return owner
end

local function toSlot(slot, owner, invType)
    if not slot then return nil end
    local meta = slot.metadata or {}
    return {
        id = { owner = tostring(owner or ''), slot = slot.slot},
        Owner = tostring(owner or ''),
        invType = invType or 1,
        Name = slot.name,
        Label = slot.label,
        Slot = slot.slot,
        Count = slot.count,
        Quality = meta.quality or 100,
        durability = meta.durability or 100,
        CreateDate = meta.CreateDate or os.time(),
        MetaData = meta,
    }
end

-- ox calls this after setPlayerInventory to build the player data table stored on inv.player

function server.setPlayerData(player)
    if not player.groups then
        print('^1[mythic-ox-bridge] setPlayerData no groups for' .. tostring(player.name) .. '^0')
    end
    return {
        source = player.source,
        name = player.name,
        groups = player.groups or {},
        sex = player.sex or 0,
        dateofbirth = player.dateofbirth or '',
    }
end

-- build a lookup of item states from all items that have a state field 
-- this should mirror mythic inventories update shit 
local function buildItemStateMap()
    local stateMap = {}
    local allItems = lib.load('data.mythic-items.index')
    if allItems then
        for _, item in ipairs(allItems) do
            if item.name and item.state then
                stateMap[item.name] = item.state
            end
        end
    end
    return stateMap
end

local ItemStateMap = buildItemStateMap()

local function updateCharacterStates(source, inv)
    local player = exports['mythic-base']:FetchComponent('Fetch'):Source(source)
    if not player then return end
    local char = player:GetData('Character')
    if not char then return end
    local playerStates = char:GetData('States') or {}
    local inventoryStates = {}

    -- collect all states
    for _, slotData in pairs(inv.items or {}) do
        if slotData and slotData.name then
            local state = ItemStateMap[slotData.name]
            if state then
                inventoryStates[state] = true
            end
        end
    end

    local changed = false

    -- add states from inventory that arent there?????
    for state in pairs(inventoryStates) do
        local found = false
        for _, s in ipairs(playerStates) do
            if s == state then found = true break end
        end
        if not found then
            table.insert(playerStates, state)
            changed = true
        end
    end

    -- remove state aka drops (skip script/access prefixed ones)
    for i = #playerStates, 1, -1 do
        local s = playerStates[i]
        if not inventoryStates[s]
            and s:sub(1, 6) ~= 'SCRIPT'
            and s:sub(1, 6) ~= 'ACCESS'
        then
            table.remove(playerStates, i)
            changed = true
        end
    end
    if changed then
        char:SetData('States', playerStates)
    end
end

-- cash is handled entirely by the mythic Wallet component (char:GetData/SetData 'Cash')
-- ox shop payments route through server.canAfford / server.removeMoney in shops/server.lua
-- no money item in inventory, no bidirectional sync needed
function server.syncInventory(inv)
    if not inv?.player then return end
    updateCharacterStates(inv.player.source, inv)
end

function server.hasGroup(inv, group)
    if not inv?.player then return end
    if type(group) == 'table' then
        for name, requiredRank in pairs(group) do
            local groupRank = inv.player.groups[name]
            if groupRank then
                if type(requiredRank) == 'table' then
                    if lib.table.contains(requiredRank, groupRank) then
                        return name, groupRank
                    end
                else
                    if groupRank >= (requiredRank or 0) then
                        return name, groupRank
                    end
                end
            end
        end
    else
        local groupRank = inv.player.groups[group]
        if groupRank then return group, groupRank end
    end
end

-- checks qualifications (driving license, weapon license etc) on the character
function server.hasLicense(inv, name)
    if not inv?.player then return false end
    local player = exports['mythic-base']:FetchComponent('Fetch'):Source(inv.player.source)
    if not player then return false end
    local char = player:GetData('Character')
    if not char then return false end
    local quals = char:GetData('Qualifications') or {}
    for _, v in ipairs(quals) do
        if v == name then return true end
    end
    return false
end

-- every single mythic resource registers item callbacks through here so this HAS to work
local ItemCallbacks = {}

Inventory.Items = {
    RegisterUse = function(self, itemName, id, cb)
        ItemCallbacks[itemName] = ItemCallbacks[itemName] or {}
        ItemCallbacks[itemName][id] = cb
    end,

    GetData = function (self, name)
       return Items(name) 
    end,

    GetCount = function(self, owner, invType, itemName)
        local target = toTarget(owner, invType)
        if not target then return 0 end
        local inv = Inventory(target)
        if not inv then return 0 end
        return Inventory.GetItemCount(inv, itemName) or 0
    end,

    GetFirst = function(self, owner, invType, itemName)
        local target = toTarget(owner, invType)
        if not target then return nil end
        local slot = Inventory.GetSlotWithItem(Inventory(target), itemName)
        return toSlot(slot, owner, invType)
    end,

    GetAll = function(self, owner, invType, itemName, slotNum)
        local target = toTarget(owner, invType)
        if not target then return {} end
        local inv = Inventory(target)
        if not inv or not inv.items then return {} end
        local result = {}
        for _, slot in pairs(inv.items) do
            if slot.name == itemName then
                result[#result + 1] = toSlot(slot, owner, invType) 
            end
        end
        return result
    end,

    GetDurability = function(self, owner, invType, itemName, slotNum)
        local target = toTarget(owner, invType)
        if not target then return 0 end
        local slot = Inventory.GetSlot(Inventory(target), slotNum)
        if not slot then return 0 end
        return math.max(0, math.min(100, (slot.metadata or {}).durability or 100))
    end,

    Broken = function(self, owner, invType, itemName, slotNum)
        return self:GetDurability (owner, invType, itemName, slotNum) <= 0
    end,

    Has = function(self, owner, invType, itemName, count)
        return self:GetCount(owner, invType, itemName)>= (count or 1)
    end,

    HasAnyItems = function(self, source, items)
        for _, v in ipairs(items) do
            local key = v.item or v.name
            if (Inventory.GetItemCount(Inventory(source), key) or 0) >= (v.count or 1) then
                return true
            end
        end
        return false
    end,
    
    -- used EVERYWHERE (150+ calls), removes a specific slot
    -- owner = SID for players, stash/container ID for everything else
    RemoveSlot = function(self, owner, name, count, slotNum, invType)
        local target = toTarget(owner, invType)
        if not target then return false end
        return Inventory.RemoveItem(Inventory(target), name, count or 1, nil, slotNum)
    end,

    -- removes by slot object reference, robbery and police use this a lot
    -- slot is the mythic slot object with .Owner .Name .Slot .invType fields
    RemoveId = function(self, owner, invType, slot)
        local target = toTarget(owner, invType)
        if not target then return false end
        return Inventory.RemoveItem(Inventory(target), slot.Name or slot.name, 1, nil, slot.Slot or slot.slot)
    end,

    -- plain remove by item name and count, no slot targeting
    Remove = function(self, owner, invType, itemName, count)
        local target = toTarget(owner, invType)
        if not target then return false end
        return Inventory.RemoveItem(Inventory(target), itemName, count or 1)
    end,

    -- nukes every stack of an item, robbery uses this to clear access codes etc
    RemoveAll = function(self, owner, invType, itemName)
        local target = toTarget(owner, invType)
        if not target then return true end
        local inv = Inventory(target)
        local count = Inventory.GetItemCount(inv, itemName) or 0
        if count > 0 then return Inventory.RemoveItem(inv, itemName, count)
        end
        return true
    end,

    --removes a list of items in one call, weed and drugs use this for multi-ingredient recipes
    -- items = {{ name = 'thing', count = 1 }, ...}
    RemoveList = function(self, owner, invType, items)
        for _, v in ipairs(items) do
            self:Remove(owner, invType, v.name, v.count or 1)
        end
    end,

}

-- ox calls this when someone uses a non-weapon item with no consume set
-- translates ox slot data back into the mythic item format that callbacks expect
function server.UseItem(source, itemName, data)
    local callbacks = ItemCallbacks[itemName]
    local mythicItem = toSlot(data, source, 1)
    local itemDef = Items(itemName)
    local pbConfig = itemDef and itemDef.server and itemDef.server.pbConfig

    if pbConfig then
        local Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
        if Callbacks then
            local p = promise.new()
            Callbacks:ClientCallback(source, 'Inventory:UseItem:Progress', {
                pbConfig = pbConfig,
                item = mythicItem,
            }, function(success)
                p:resolve(success)
            end)
            if not Citizen.Await(p) then return end
        end
    end

    if callbacks then
        for _, cb in pairs(callbacks) do
            cb(source, mythicItem, itemDef)
        end
    end

    -- auto remove if flagged as consumed but only if a callback didnt already pull it
    if itemDef and itemDef.server and itemDef.server.isRemoved then
        local stillThere = Inventory.GetSlot(Inventory(source), data.slot)
        if stillThere and stillThere.name == itemName then
            Inventory.RemoveItem(Inventory(source), itemName, 1, data.metadata, data.slot)
        end
    end
end

-- the shims that make FetchComponent('Inventory') work without changing any other resource
-- capture originals BEFORE replacing so inner calls use the real ox functions
-- shims detect calling convention: ox-internal passes an inventory object (has .slots),
-- mythic component calls pass the module table as self with owner/name/count args
local _origAddItem    = Inventory.AddItem
local _origRemoveItem = Inventory.RemoveItem

Inventory.AddItem = function(self, owner, name, count, metadata, invType)
    if type(self) == 'table' and self.slots then
        return _origAddItem(self, owner, name, count, metadata, invType)
    end
    local target = toTarget(owner, invType)
    if not target then
        print('^1[mythic-ox-bridge] AddItem: could not resolve owner ' .. tostring(owner) .. '^0')
        return false
    end
    return _origAddItem(Inventory(target), name, count or 1, metadata or {})
end

Inventory.RemoveItem = function(self, owner, name, count, metadata, invType)
    if type(self) == 'table' and self.slots then
        return _origRemoveItem(self, owner, name, count, metadata, invType)
    end
    local target = toTarget(owner, invType)
    if not target then return false end
    return _origRemoveItem(Inventory(target), name, count or 1, metadata)
end

-- all items must be present
Inventory.HasItems = function(self, source, items)
    for _, v in ipairs(items) do
        if (Inventory.GetItemCount(Inventory(source), v.item) or 0) < (v.count or 1) then
            return false
        end
    end
    return true
end

-- at least one item from the list must be present
Inventory.HasAnyItems = function(self, source, items)
    for _, v in ipairs(items) do
        if (Inventory.GetItemCount(Inventory(source), v.item) or 0) >= (v.count or 1) then
            return true
        end
    end
    return false
end

Inventory.Get = function(self, source, owner, invType, cb)
    local target = toTarget(owner or source, invType)
    if not target then
        if cb then return cb({}) end
        return {}
    end
    local inv = Inventory(target)
    if not inv then
        if cb then return cb({}) end
        return{}
    end
    local result = {}
    for i = 1, inv.slots do
        local slot = inv.items[i]
        result[i] = slot and toSlot(slot, owner or source, invType) or {}
    end
    local out = { inventory = result, owner = target, InvType = invType }
    if cb then return cb(out)end
    return out
end

Inventory.GetSlot = function(self, owner, slotNum, invType, cb)
    local target = toTarget(owner, invType)
    if not target then
        if cb then return cb(nil) end
        return nil
    end
    local slot = Inventory.GetSlot(Inventory(target), slotNum)
    local result = toSlot(slot, owner, invType)
    if cb then return cb(result) end
    return result
end

Inventory.SetMetadataKey = function(self, owner, key, value, invType, slotNum)
    local target = toTarget(owner, invType)
    if not target then return end
    local inv = Inventory(target)
    if not inv then return end
    for _, slot in pairs(inv.items) do
        if slot.slot == slotNum then
            local meta = slot.metadata or {}
            meta[key] = value
            Inventory.SetMetadata(inv, slot.slot, meta)
            return
        end
    end
end

Inventory.SlotExists = function(self, owner, slotNum, invType)
    local target = toTarget(owner, invType)
    if not target then return false end
    local slot = Inventory.GetSlot(Inventory(target), slotNum)
    return slot ~= nil and slot.name ~= nil
end

Inventory.UpdateMetaData = function(self, owner, metadata, slotNum, invType)
    local target = toTarget(owner, invType)
    if not target then return end
    local inv = Inventory(target)
    if not inv then return end
    local slot = Inventory.GetSlot(inv, slotNum)
    if not slot then return end
    local meta = slot.metadata or {}
    for k, v in pairs(metadata) do
        meta[k] = v
    end
    Inventory.SetMetadata(inv, slotNum, meta)
end

-- mythic-admin expects name/label/type/rarity/weight/price/isStackable/description
-- ox returns its own format so we remap
-- TODO: price is always 0, ox doesnt store price on item defs
Inventory.GetItemsDatabase = function(self)
    local oxItems = exports['ox_inventory']:Items()
    local result  = {}
    for name, def in pairs(oxItems) do
        result[name] = {
            name        = name,
            label       = def.label,
            type        = def.server and def.server.mythicType or 1,
            rarity      = def.server and def.server.mythicRarity or 1,
            weight      = def.weight or 0,
            price       = 0,
            isStackable  = def.stack ~= false,
            description = def.description,
        }
    end
    return result
end

Inventory.DoesItemExist = function(self, name)
    return Items(name) ~= nil
end

-- crafting calls this to know if theres space before adding output items
-- ox doesnt have a direct export for this so we dig into the inventory object
-- returns a list of free slot numbers (1-indexed, matching mythic expectation)
Inventory.GetFreeSlotNumbers = function(self, source)
    local inv = Inventory(source)
    if not inv then return {} end
    local free = {}
    for i = 1, inv.slots do
        if not inv.items[i] or not inv.items[i].name then
            free[#free + 1] = i
        end
    end
    return free
end

-- robbery calls this to track durability on thermite etc
-- ox uses per-item-def degrade minutes not per-slot create dates so this cant map 1:1
-- FIXME: slot.id in mythic is a DB row id which doesnt exist in ox
Inventory.SetItemCreateDate = function(self, slotId, value)
    -- stub, prevents crash, durability wont actually track until this is solved
end

-- handles opening stashes, trunks, gloveboxes, drops, shops
-- registers stashes with ox on first open so we dont have to preregister every single one
local registeredStashes = {}
local _polyInvs =  {}
local _shopDutyRestrictions = {
    ['armory:police'] = 'police',
    ['armory:doc'] = 'corrections',
}

local invTypeToOxType = {
    [3]  = 'stash', -- police weapon rack (pdrack:VIN)
    [4]  = 'trunk',
    [5]  = 'glovebox',
    [10] = 'drop',
    [11] = 'shop',
    [13] = 'stash',
    [27] = 'shop', --PD Armory
    [37] = 'shop', -- DOC Armory
    [44] = 'stash', -- evidence case locker
    [45] = 'stash', -- personal pd/ems locker
}

exports['ox_inventory']:registerHook('openShop', function(payload)
    local shopType = payload.shop and payload.shop.type
    local required = shopType and _shopDutyRestrictions[shopType]
    if not required then return true end
    local onDuty = Player(payload.source).state.onDuty
    if onDuty ~= required then
        return false
    end
    return true
end)

Inventory.OpenSecondary = function(self, source, invType, owner, vehClass, vehModel, isRaid, nameOverride, slotOverride, capacityOverride)
    if not source or not invType or not owner then return end

    local oxType  = invTypeToOxType[invType]
    local isStash = oxType == 'stash' or invType >= 1000

    if isStash then
        if not registeredStashes[owner] then
            exports['ox_inventory']:RegisterStash(
                owner,
                nameOverride or owner,
                slotOverride or 50,
                capacityOverride or 100000
            )
            registeredStashes[owner] = true
        end
        TriggerClientEvent('Inventory:Client:Load', source, { invType = invType, owner = owner })
    elseif invType == 11 then
        -- TODO: shops need ox-format definitions before this actually works
        TriggerClientEvent('Inventory:Client:Load', source, { invType = 11, owner = owner })
    elseif invType == 4 or invType == 5 then
        -- resolve vehicle server side by vin - dont trust client loop
        local oxInvType = invType == 4 and 'trunk' or 'glovebox'
        local targetEntity
        for _, entity in ipairs(GetAllVehicles()) do
            if Entity(entity).state.VIN == owner then
                targetEntity = entity
                break
            end
        end
        if targetEntity then
            local netId = NetworkGetNetworkIdFromEntity(targetEntity)
            exports['ox_inventory']:forceOpenInventory(source, oxInvType, { netid = netId })
        else
            print('^3[mythic-ox-bridge] OpenSecondary: no vehicle found with VIN: ' .. tostring(owner) .. ' for ' .. oxInvType .. '^0')
        end
    elseif invType == 10 then
        TriggerClientEvent('Inventory:Client:Load', source, { invType = 10, owner = owner })
    end
end

Inventory.Poly = {
    Create = function(self, storage)
        if not storage or not storage.id then return end
        local inv = storage.data and storage.data.inventory
        local owner = (inv and inv.owner) or storage.id
        local slots = (inv and inv.slots) or 50
        local capacity = (inv and inv.capacity) or 100000

        local invType = inv and inv.invType or 13
        local oxType = invTypeToOxType[invType] or 'stash'
        if oxType ~= 'shop' and not registeredStashes[owner] then
            exports['ox_inventory']:RegisterStash(owner, storage.name or storage.id, slots, capacity)
            registeredStashes[owner] = true
        end
        table.insert(_polyInvs, storage.id)
        GlobalState[('Inventory:%s'):format(storage.id)] = storage
    end
}

-- state bag sync, items with a state field in their def auto-set that state on the character
-- skips SCRIPT_ and ACCESS_ prefixes, those are handled elsewhere
local function UpdateCharacterItemStates(source, itemName, adding)
    local itemDef = Items(itemName)
    if not itemDef or not itemDef.server or not itemDef.server.state then return end

    local state = itemDef.server.state
    if state:sub(1, 7) == 'SCRIPT_' or state:sub(1, 7) == 'ACCESS_' then return end

    local charState = Player(source).state
    local states    = charState.ItemStates or {}
    states[state]   = adding and true or nil
    charState:set('ItemStates', states, true)
end

exports['ox_inventory']:registerHook('addItem', function(payload)
    UpdateCharacterItemStates(payload.source, payload.item, true)
end)

exports['ox_inventory']:registerHook('removeItem', function(payload)
    UpdateCharacterItemStates(payload.source, payload.item, false)
end)

-- openInventory hook fires when ox opens any secondary inventory
-- mythic-labor coke job listens to Inventory:Server:Opened(source, owner, invType) to track trunk opens
-- payload.inventoryId for trunks is 'trunk'..VIN so we strip the prefix for the mythic event
exports['ox_inventory']:registerHook('openInventory', function(payload)
    local oxType     = payload.inventoryType
    local invTypeNum = ({ trunk=4, glovebox=5, drop=10, shop=11, stash=13 })[oxType] or 13
    local owner      = payload.inventoryId

    -- strip the 'trunk'/'glove' prefix ox adds so mythic resources get the raw VIN/plate
    if oxType == 'trunk' and owner:sub(1, 6) == 'trunk-' then
        owner = owner:sub(7)
    elseif oxType == 'glovebox' and owner:sub(1, 6) == 'glove-' then
        owner = owner:sub(7)
    end

    TriggerEvent('Inventory:Server:Opened', payload.source, owner, invTypeNum)
end)

local _Loot = {}

_Loot.CustomWeightedSet = function(self, items, source, owner, invType)
    if not items or #items == 0 then return end
    local total = 0
    for _, v in ipairs(items) do total = total + (v.weight or 1) end
    local roll = math.random() * total
    local cumulative = 0

    for _, v in ipairs(items) do
        cumulative = cumulative + (v.weight or 1)
        if roll <= cumulative then
            if source and v.name then
                local target = toTarget(owner or source, invType or 1)
                exports['ox_inventory']:AddItem(target, v.name, v.count or 1)
            end
            return v
        end
    end
end

_Loot.WeightedSet = _Loot.CustomWeightedSet
exports['mythic-base']:RegisterComponent('Loot', _Loot)

-- TODO: crafting system is NOT bridged
-- mythic-crafting uses:
--   Inventory.Items:Has(source, name, count)       <- shimmed above
--   Inventory.Items:Remove(owner, invType, name, count, skipUpdate) <- skipUpdate flag ignored, should be fine
--   Inventory:GetFreeSlotNumbers(source)           <- shimmed above
--   Inventory:AddItem(source, name, count, meta)   <- shimmed above
--   Crafting:RegisterBench(id, config)             <- NOT shimmed, mythic-crafting registers benches via FetchComponent('Crafting')
--   crafting_cooldowns DB table in MySQL           <- doesnt exist in ox db, will error on first craft
-- FIXIT: either bridge mythic-crafting's RegisterBench into ox's RegisterCraft system,
--        or port mythic-crafting to call exports['ox_inventory'] directly
--        for now the stub below prevents crash-on-nil but crafting wont actually work

-- stub crafting component so resources dont explode on FetchComponent('Crafting')
-- everything returns false/nil, nothing will actually craft
-- FIXIT: replace this with real logic when you get around to it
local CraftingStub = {
    RegisterBench = function(self, id, config)
        print('^3[mythic-ox-bridge] Crafting:RegisterBench called for bench "' .. tostring(id) .. '" - crafting not bridged yet, ignoring^0')
    end,
    CanCraft = function(self, ...) return false end,
    StartCraft = function(self, ...) return false end,
}

-- mythic lifecycle hooks
AddEventHandler('Proxy:Shared:RegisterReady', function()
    local Middleware = exports['mythic-base']:FetchComponent('Middleware')
    local Fetch      = exports['mythic-base']:FetchComponent('Fetch')
    local Config     = exports['mythic-base']:FetchComponent('Config')

    -- on character spawn we build the plain table ox expects and call its setPlayerInventory
    -- ox then loads the DB inventory, creates the inv object, and calls our server.setPlayerData
    Middleware:Add('Characters:Spawning', function(source)
        local player = Fetch:Source(source)
        if not player then return end
        local char = player:GetData('Character')
        if not char then return end

        local jobs   = char:GetData('Jobs') or {}
        local groups = {}
        for _, v in ipairs(jobs) do
            groups[v.Id] = v.Grade and v.Grade.Level or 0
        end

        server.setPlayerInventory({
            source      = source,
            name        = player:GetData('Name'),
            identifier  = char:GetData('SID'),
            groups      = groups,
            sex         = char:GetData('Gender') or 0,
            dateofbirth = char:GetData('DOB') or '',
        })
        TriggerClientEvent('Inventory:Client:PolySetup', source, _polyInvs)
    end, 5)

    -- close and remove inventory on character logout
    -- note: playerDropped is handled by ox's generic bridge/server.lua already
    Middleware:Add('Characters:Logout', function(source)
        local inv = Inventory(source)
        if inv and inv.player then
            inv:closeInventory()
            Inventory.Remove(inv)
        end
        return true
    end, 5)

    -- give new characters their starter items
    Middleware:Add('Characters:Created', function(source)
        local startItems = Config:GetData('StartItems') or {}
        for slot, item in ipairs(startItems) do
            exports['ox_inventory']:AddItem(source, item.name, item.count, {}, slot)
        end
        return true
    end, 5)

    exports['mythic-base']:RegisterComponent('Inventory', Inventory)
    exports['mythic-base']:RegisterComponent('Crafting', CraftingStub)
end)

-- load mythic items from within this execution chain
-- (standalone server_scripts have their own require cache and write to a dead ItemList)
local ok, err = pcall(require, 'modules.bridge.mythic.items')
if not ok then print('^1[mythic-ox-bridge] items load error: ' .. tostring(err) .. '^0') end

-- rebuild groups when someones job changes
AddEventHandler('Jobs:Server:JobUpdate', function(source)
    local inv = Inventory(source)
    if not inv or not inv.player then return end

    local player = exports['mythic-base']:FetchComponent('Fetch'):Source(source)
    if not player then return end
    local char = player:GetData('Character')
    if not char then return end

    local groups = {}
    for _, v in ipairs(char:GetData('Jobs') or {}) do
        groups[v.Id] = v.Grade and v.Grade.Level or 0
    end
    inv.player.groups = groups
end)

RegisterNetEvent('ox_inventory:bridge:openShop', function(shopId)
    local src = source
    Inventory.OpenSecondary(Inventory.Items, src, 11, ('shop:%s'):format(tostring(shopId)))
end)

RegisterNetEvent('ox_inventory:bridge:openTrunk', function(netId)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    local vin = Entity(entity).state.VIN
    if not vin then return end
    exports['ox_inventory']:forceOpenInventory(src, 'trunk', {netid = netId})
end)

local _shopPedData = nil
local function buildShopPedData()
    if _shopPedData then return _shopPedData end
    local shopDefs = lib.load('data.shops') or {}
    _shopPedData = {}
    for shopType, shopData in pairs(shopDefs) do
        if shopData.locations and shopData.npc then
            for i, loc in ipairs(shopData.locations) do
                _shopPedData[#_shopPedData+1] = {
                    id = shopType .. '_' .. i,
                    shopType = shopType,
                    locId = i,
                    name = shopData.name,
                    npc = shopData.npc,
                    coords = { x= loc.x, y = loc.y, z = loc.z, h = loc.w or 0.0 },
                    blip = shopData.blip,
                }
            end
        end
    end
    return _shopPedData
end

RegisterNetEvent('ox_inventory:bridge:getShops', function()
    TriggerClientEvent('ox_inventory:bridge:receiveShops', source, buildShopPedData())
end)