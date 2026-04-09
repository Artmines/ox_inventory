-- mythic ox bridge : client side
-- handles client side inv events for mythic compatibility
--
-- TODO: client cached inventory not bridged
-- mythic sends Inventory:Client:Cache with the full inventory array after any change
-- resources read from this cache for local HasItem checks instead of server roundtrips
-- our Check.Player.HasItem calls Search() export which is probably fine latency-wise
-- but if something is checking items every frame it will be slow as hell
-- FIXIT: listen to Inventory:Client:Cache and cache locally, swap Check.Player.* to use cache
--
-- TODO: item use progress bar (Inventory:ItemUse client callback) not bridged
-- mythic-inventory server sends this to client with pbConfig before firing server.UseItem
-- client runs the progress bar, returns success/cancelled back to server
-- ox has its own item use system, so this whole round-trip doesnt happen our way
-- most items will just fire instantly without the animation which looks jank
-- FIXIT: when server.UseItem fires, check itemDef for pbConfig and trigger ox progress bar manually

-- ============================================================
-- Stubs defined first so load-time RegisterComponent calls work
-- ============================================================

local WeaponsStub = {}

_polyShopRestrictions = {
    ['armory:police'] = 'police',
    ['armory:doc'] = 'corrections'
}

_polyShopTypes = {
    [27] = 'armory:police',
    [37] = 'armory:doc',
}

WeaponsStub.GetEquippedItem = function(self)
    return nil
end

WeaponsStub.GetEquippedHash = function(self)
    return nil
end

WeaponsStub.UnequipIfEquippedNoAnim = function(self)
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon and weapon ~= `WEAPON_UNARMED` then
        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    end
end

local CraftingStub = {
    RegisterBench = function() end,
    CanCraft      = function() return false end,
}

local _spawnedBenchEntities = {}
local _pendingBenches       = nil
local _PedInteraction       = nil
local _Targeting            = nil
local _vendingSetup = false

local function setupVendingMachines()
    if _vendingSetup or not _Targeting then return end
    _vendingSetup = true
    local shops = lib.load('data.shops') or {}
    for key, shop in pairs(shops) do
        if shop.models and shop.icon and shop.text then
            local shopType = key:match('^shop:(.+)$')
            if shopType then
                for _, model in ipairs(shop.models) do
                    _Targeting:AddObject(model, shop.icon, {
                        {
                            text    = shop.text,
                            icon    = shop.icon,
                            event   = 'Shop:Client:OpenShop',
                            data    = shopType,
                            minDist = 3.0,
                        },
                    }, 3.0)
                end
            end
        end
    end
end

local function setupAllBenches()
    if not _pendingBenches or not _PedInteraction or not _Targeting then return end

    setupVendingMachines()

    for _, bench in ipairs(_pendingBenches) do
        -- register in client CraftingBenches so openInventory can find the bench data
        if bench.oxData then
            exports['ox_inventory']:RegisterCraftingBench(bench.id, bench.oxData)
        end

        local id        = bench.id
        local targeting = bench.targeting
        local location  = bench.location

        if not targeting or not location then goto continue end

        local coords, heading
        if type(location) == 'vector3' or type(location) == 'vector4' then
            coords  = vector3(location.x, location.y, location.z)
            heading = 0.0
        elseif type(location) == 'table' and location.x and location.y and location.z then
            coords  = vector3(location.x, location.y, location.z)
            heading = location.h or 0.0
        else
            goto continue
        end

        local menu = {
            {
                icon  = targeting.icon or 'fa-hammer',
                text  = bench.label or 'Craft',
                event = 'Crafting:Client:OpenCrafting',
                data  = { id = id },
            },
        }

        if targeting.ped then
            _PedInteraction:Add(
                id,
                GetHashKey(targeting.ped.model),
                coords,
                heading,
                25.0,
                menu,
                targeting.icon or 'fa-hammer',
                targeting.ped.task
            )
        elseif targeting.model then
            local obj = CreateObject(GetHashKey(targeting.model), coords.x, coords.y, coords.z, false, true, false)
            FreezeEntityPosition(obj, true)
            SetEntityHeading(obj, heading)
            _spawnedBenchEntities[id] = obj
            _Targeting:AddEntity(obj, targeting.icon or 'fa-hammer', menu)
        elseif targeting.poly then
            _Targeting.Zones:AddBox(
                id,
                targeting.icon or 'fa-hammer',
                targeting.poly.coords,
                targeting.poly.w or 2.0,
                targeting.poly.l or 2.0,
                targeting.poly.options,
                menu,
                2.0,
                true
            )
        end

        ::continue::
    end

    _Targeting.Zones:Refresh()
end

-- cache schematic bench oxData so we can build per-player locked states
local _schematicBenchOxData = nil

RegisterNetEvent('ox_inventory:bridge:SetupCraftingBenches', function(benches)
    _pendingBenches = benches
    -- capture schematic bench data for per-player unlock injection
    for _, bench in ipairs(benches) do
        if bench.id == 'crafting-schematics' and bench.oxData then
            _schematicBenchOxData = bench.oxData
            break
        end
    end
    CreateThread(function()
        Wait(2000)
        _PedInteraction = exports['mythic-base']:FetchComponent('PedInteraction')
        _Targeting      = exports['mythic-base']:FetchComponent('Targeting')
        setupAllBenches()
    end)
end)

AddEventHandler('Crafting:Client:OpenCrafting', function(ent, data)
    if data.id == 'crafting-schematics' and _schematicBenchOxData then
        -- apply per-player unlock states before opening
        local unlocked = LocalPlayer.state.unlockedSchematics or {}
        local modifiedItems = {}
        for i, item in ipairs(_schematicBenchOxData.items or {}) do
            local newItem = table.clone(item)
            newItem.metadata = table.clone(item.metadata or {})
            newItem.metadata.locked = not unlocked[newItem.metadata.schematic]
            modifiedItems[i] = newItem
        end
        local modifiedData = table.clone(_schematicBenchOxData)
        modifiedData.items = modifiedItems
        exports['ox_inventory']:RegisterCraftingBench('crafting-schematics', modifiedData)
    end
    exports['ox_inventory']:openInventory('crafting', { id = data.id, index = 1 })
end)


-- Register stubs immediately at load time — other resources fetch these
-- during their RegisterReady handlers which fire after ox_inventory loads
exports['mythic-base']:RegisterComponent('Weapons', WeaponsStub)
exports['mythic-base']:RegisterComponent('Crafting', CraftingStub)

-- ============================================================
-- Inventory shim
-- ============================================================

-- every mythic resource gets Inventory via FetchComponent('Inventory') not a global
-- we build the client shim table and register it as the Inventory component
local ClientInventory = {
    -- mythic-targeting gates interactions behind these item checks
    Check = {
        Player = {
            HasItem = function(self, item, count)
                return (exports['ox_inventory']:Search('count', item) or 0) >= (count or 1)
            end,

            -- all items must be present
            HasItems = function(self, items)
                for _, v in ipairs(items) do
                    if (exports['ox_inventory']:Search('count', v.item or v.name) or 0) < (v.count or 1) then
                        return false
                    end
                end
                return true
            end,

            -- at least one item from the list
            HasAnyItems = function(self, items)
                for _, v in ipairs(items) do
                    if (exports['ox_inventory']:Search('count', v.item or v.name) or 0) >= (v.count or 1) then
                        return true
                    end
                end
                return false
            end,
        }
    },

    -- mythic-laptop calls this after ItemsLoaded fires to populate its item list
    Items = {
        GetData = function(self)
            return exports['ox_inventory']:Items() or {}
        end,

        GetCount = function(self, item)
            return exports['ox_inventory']:Search('count', item) or 0
        end,

        Has = function(self, item, count)
            return self:GetCount(item) >= (count or 1)
        end,

        -- mythic-ped calls this to check if the player has a cosmetic item equipped
        -- searches item definitions for staticMetadata matching ped appearance
        -- our items don't carry staticMetadata so we always return nil (safe — means "not catalogued item")
        GetWithStaticMetadata = function(self, masterKey, mainIdName, textureIdName, gender, data)
            return nil
        end,
    },

    Search = {
        Character = function(self, serverId)
            exports['ox_inventory']:openInventory('player', serverId)
        end,
    },

    -- mythic-phone calls Inventory.Close:All() before opening
    Close = {
        All = function(self)
            exports['ox_inventory']:closeInventory()
        end,
    },
}

-- register with mythic-base so every resource that calls FetchComponent('Inventory') gets our shim
AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('Inventory', ClientInventory)

    local Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    local Progress = exports['mythic-base']:FetchComponent('Progress')

    if Callbacks and Progress then
        Callbacks:RegisterClientCallback('Inventory:ItemUse', function(data, cb)
            local Anims = exports['mythic-base']:FetchComponent('Animations')

            if data.anim and (not data.pbConfig or not data.pbConfig.animation) then
                if Anims and Anims.Emotes then
                    Anims.Emotes:Play(data.anim, false, data.time, true)
                end
            end

            if data.pbConfig then
                Progress:Progress({
                    name = data.pbConfig.name,
                    duration = data.time,
                    label = data.pbConfig.label,
                    useWhileDead = data.pbConfig.useWhileDead,
                    canCancel = data.pbConfig.canCancel,
                    vehicle = data.pbConfig.vehicle,
                    disarm = data.pbConfig.disarm,
                    ignoreModifier = data.pbConfig.ignoreModifier or true,
                    animation = data.pbConfig.animation or false,
                    controlDisables = {
                        disableMovement = data.pbConfig.disableMovement,
                        disableCarMovement = data.pbConfig.disableCarMovement,
                        disableMouse = data.pbConfig.disableMouse,
                        disableCombat = data.pbConfig.disableCombat,
                    },
                }, function(cancelled)
                    pcall(function()
                        if Anims and Anims.Emotes then Anims.Emotes:ForceCancel() end
                    end)
                    cb(not cancelled)
                end)
            else
                cb(true)
            end
        end)
        Callbacks:RegisterClientCallback('Inventory:Compartment:Open', function(data, cb)
            exports['ox_inventory']:closeInventory()
            cb(true)
        end)
    end
end)

-- force close when logging out
AddEventHandler('Characters:Client:Logout', function()
    exports['ox_inventory']:closeInventory()
end)

-- enable everything on spawn, also fires ItemsLoaded so mythic-laptop can init its item list
AddEventHandler('Characters:Client:Spawned', function()
    LocalPlayer.state:set('invBusy', false, true)
    LocalPlayer.state:set('invHotKeys', true, false)
    LocalPlayer.state:set('canUseWeapons', true, false)
    TriggerEvent('Inventory:Client:ItemsLoaded')
end)

-- disable weapons on death
AddEventHandler('Ped:Client:Died', function()
    exports['ox_inventory']:closeInventory()
    LocalPlayer.state:set('canUseWeapons', false, false)
end)

-- old mythic open request, just pass it through
RegisterNetEvent('Inventory:Client:Open', function(data)
    exports['ox_inventory']:openInventory('player', data)
end)

-- secondary inventory opens, this one was a pain in the ass to figure out
RegisterNetEvent('Inventory:Client:Load', function(data)
    -- trunk/glovebox (invtype 4/5) no longer handled here (no need to)
    -- server calls forceOpenInventory directly
    if data.invType == 13 or data.invType == 3 or data.invType == 44 or data.invType == 45 or data.invType >= 1000 then
        -- stash: regular, police rack, evidence lockers, property safes etc
        exports['ox_inventory']:openInventory('stash', {
            id = data.owner,
        })
    elseif data.invType == 10 then
        exports['ox_inventory']:openInventory('drop', {
            id = data.owner,
        })
    elseif data.invType == 11 then
        -- TODO: shops need ox-format definitions or this shows nothing useful
        exports['ox_inventory']:openInventory('shop', {
            type = data.owner,
        })
    end

end)

-- server said close it
RegisterNetEvent('Inventory:CloseUI', function()
    exports['ox_inventory']:closeInventory()
end)

-- item added/removed notifications
RegisterNetEvent('Inventory:Client:Changed', function(data)
    if data.added then
        exports['ox_inventory']:notify({
            id          = 'item_added',
            title       = data.label,
            description = 'x' .. data.count,
            icon        = 'circle-plus',
            iconColor   = '#4CAF50',
            duration    = 3000,
        })
    else
        exports['ox_inventory']:notify({
            id          = 'item_removed',
            title       = data.label,
            description = 'x' .. data.count,
            icon        = 'circle-minus',
            iconColor   = '#F44336',
            duration    = 3000,
        })
    end
end)

-- weapon equip/unequip from mythic weapon system
RegisterNetEvent('Weapons:Client:Use', function(data)
    if data == nil or data.slot == nil then
        TriggerEvent('ox_inventory:disarm', false)
    end
end)

-- force unequip on arrest, death etc
RegisterNetEvent('Weapons:Client:ForceUnequip', function()
    TriggerEvent('ox_inventory:disarm', true)
end)

-- prevents using items while already mid-use
RegisterNetEvent('Inventory:Client:InUse', function(state)
    LocalPlayer.state:set('invBusy', state, true)
end)

-- lock inventory and disarm when cuffed
AddStateBagChangeHandler('isCuffed', ('player:%s'):format(cache.serverId), function(_, _, value)
    LocalPlayer.state:set('invBusy', value or false, false)
    if value then
        exports['ox_inventory']:closeInventory()
        TriggerEvent('ox_inventory:disarm', true)
    end
end)

-- same thing on death
AddStateBagChangeHandler('isDead', ('player:%s'):format(cache.serverId), function(_, _, value)
    LocalPlayer.state:set('invBusy', value or false, false)
    if value then
        exports['ox_inventory']:closeInventory()
        TriggerEvent('ox_inventory:disarm', true)
    end
end)

AddStateBagChangeHandler('doingAction', ('player:%s'):format(cache.serverId), function(_, _, value)
    LocalPlayer.state:set('invBusy', value or false, false)
end)

local ClientItems = require 'modules.items.shared'
local allItems = lib.load('data.mythic-items.index')

if allItems then
    local count = 0
    for _, item in ipairs(allItems) do
        if item.name and not ClientItems[item.name] then
            ClientItems[item.name] = {
                name = item.name,
                label = item.label or item.name,
                description = item.description or nil,
                weight = item.weight or 0,
                stack = item.isStackable ~= false and (item.isStackable or true),
                close = item.closeUi or true,
                count = 0,
            }
            count = count + 1
        end
    end
    print(string.format('^2[mythic-ox-bridge] registered %d items client-side^0', count))
end

local mythicItemCache = {}

AddEventHandler('ox_inventory:updateInventory', function()
    mythicItemCache = {}
    local idx = 0
    for slot, slotData in pairs (PlayerData.inventory or {}) do
        if slotData and slotData.name then
            idx = idx + 1
            mythicItemCache[idx] = {
                Name = slotData.name,
                Label = slotData.label or slotData.name,
                Slot = slot,
                Count = slotData.count or 0,
                Quality = (slotData.metadata or {}).quality or 100,
                MetaData = slotData.metadata or {},
                Owner = tostring(cache.serverId),
                invType = 1,
            }
        end
    end
    TriggerEvent('Inventory:Client:Cache', mythicItemCache)
end)

-- swap has item checks to use local cache (avoid server roundtrip per frame)
ClientInventory.Check.Player.HasItem = function(self, item, count)
    if next(mythicItemCache) then
        local total = 0
        for _, slot in pairs(mythicItemCache) do
            if slot.Name == item then total = total + (slot.Count or 0) end
        end
        return total >= (count or 1)
    end
    return (exports['ox_inventory']:Search('count', item) or 0) >= (count or 1)
end

ClientInventory.Check.Player.HasItems = function(self, items)
    for _,v in ipairs(items) do
        local name = v.item or v.name
        local needed = v.count or 1
        local total = 0
        for _, slot in pairs(mythicItemCache) do
            if slot.Name == name then total = total + (slot.Count or 0) end
        end
        if total < needed then return false end
    end
    return true
end

ClientInventory.Check.Player.HasAnyItems = function(self, items)
    for _, v in ipairs(items) do
        local name = v.item or v.name
        local needed = v.count or 1
        local total = 0
        for _, slot in pairs(mythicItemCache) do
            if slot.Name == name then total = total + (slot.Count or 0) end
        end
        if total >= needed then return true end
    end
    return false
end

ClientInventory.Items.GetCount = function(self, item)
    local total = 0
    for _, slot in pairs(mythicItemCache) do
        if slot.Name == item then total = total + (slot.Count or 0) end
    end
    return total
end

ClientInventory.Items.Has = function(self, item, count)
    return ClientInventory.Items:GetCount(item) >= (count or 1)
end

ClientInventory.Shop = {
    Open = function(self, shopId)
       TriggerServerEvent('ox_inventory:bridge:openShop', shopId) 
    end,
}

AddEventHandler('Inventory:Client:Trunk', function(entity)
    TriggerServerEvent('ox_inventory:bridge:openTrunk', NetworkGetNetworkIdFromEntity(entity.entity))    
end)

AddEventHandler('Characters:Client:Spawn', function()
    TriggerServerEvent('ox_inventory:bridge:getShops')
end)

RegisterNetEvent('ox_inventory:bridge:receiveShops', function(shops)
    local PedInteraction = exports['mythic-base']:FetchComponent('PedInteraction')
    local Blips = exports['mythic-base']:FetchComponent('Blips')
    if not shops or not PedInteraction then return end
    for _, v in ipairs(shops) do
        PedInteraction:Add(
            'shop-' .. v.id,
            GetHashKey(v.npc),
            vector3(v.coords.x, v.coords.y, v.coords.z),
            v.coords.h,
            25.0,
            {{
                icon = 'sack-dollar',
                text = v.name or 'Shop',
                event = 'Shop:Client:OpenShop',
                data = { shopType = v.shopType, locId = v.locId },
            }},
            'shop'
        )
        if v.blip and Blips then
            Blips:Add(
                'inventory_shop_' .. v.id,
                v.name, 
                vector3(v.coords.x, v.coords.y, v.coords.z),
                v.blip.id,
                v.blip.colour,
                v.blip.scale
            )
        end
    end
end)

AddEventHandler('Shop:Client:OpenShop', function(obj, data)
    if type(data) == 'string' then
        -- vending machines / direct shop type strings (e.g. "vending-coffee")
        exports['ox_inventory']:openInventory('shop', { type = 'shop:' .. data })
    else
        -- NPC shops with shopType + locId table
        exports['ox_inventory']:openInventory('shop', { type = data.shopType, id = data.locId })
    end
end)

_inInvPoly = nil

RegisterNetEvent('Inventory:Client:PolySetup', function(locs)
    local Polyzone = exports['mythic-base']:FetchComponent('Polyzone')
    if not Polyzone or not locs then return end
    for _, id in ipairs(locs) do
        local data = GlobalState[('Inventory:%s'):format(id)]
        if data then
            if data.data then
                data.data.isInventory = true
                data.data.name = data.name
            end
            if data.type == 'box' then
                Polyzone.Create:Box(data.id, data.coords, data.length, data.width, data.options, data.data)
            elseif data.type == 'poly' then
                Polyzone.Create:Poly(data.id, data.points, data.options, data.data)
            else
                Polyzone.Create:Circle(data.id, data.coords, data.radius, data.options, data.data)
            end
        end
    end
end)

AddEventHandler('Polyzone:Enter', function(id, testedPoint, insideZones, data)
    if not data or not data.isInventory then return end
    local Action = exports['mythic-base']:FetchComponent('Action')
    if Action then Action:Show('Open '.. (data.name or 'Storage')) end
    _inInvPoly = data
    LocalPlayer.state:set('_inInvPoly', data, false)
end)

AddEventHandler('Polyzone:Exit', function(id, testedPoint, insideZones, data)
    if not data or not data.isInventory then return end
    local Action = exports['mythic-base']:FetchComponent('Action')
    if Action then Action:Hide() end
    if LocalPlayer.state.inventoryOpen then
        client.closeInventory()
    end
    _inInvPoly = nil
    LocalPlayer.state:set('_inInvPoly', nil, false)
end)