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
    },

    Search = {
        Character = function(self, serverId)
            exports['ox_inventory']:openInventory('player', serverId)
        end,
    },
}

-- register with mythic-base so every resource that calls FetchComponent('Inventory') gets our shim
AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('Inventory', ClientInventory)
    local Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    local Progress = exports['mythic-base']:FetchComponent('Progress')

    if Callbacks and Progress then
        Callbacks:RegisterClientCallback('Inventory:UseItem:Progress', function(data, cb)
            Progress:Start(data.pbConfig, function(success)
                cb(success ~= false)
            end)
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
    if data.invType == 4 or data.invType == 5 then
        -- trunk or glovebox
        -- ox needs the vehicle netid for proper slot/weight lookup and security checks
        -- owner is the VIN from mythic state bag, we find the vehicle entity locally
        local invType = data.invType == 4 and 'trunk' or 'glovebox'
        local netId

        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if Entity(veh).state.VIN == data.owner then
                netId = NetworkGetNetworkIdFromEntity(veh)
                break
            end
        end

        if netId then
            exports['ox_inventory']:openInventory(invType, {
                netid = netId,
                model = data.vehModel,
                class = data.vehClass,
            })
        else
            -- vehicle wasnt found locally, this probably means something went wrong upstream
            print('^3[mythic-ox-bridge] couldnt find vehicle with VIN ' .. tostring(data.owner) .. ' for trunk open^0')
        end
    elseif data.invType == 13 or data.invType == 3 or data.invType == 44 or data.invType == 45 or data.invType >= 1000 then
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
