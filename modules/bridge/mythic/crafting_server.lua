-- bridge: load mythic crafting configs and register all benches into ox
-- runs at server start, fires after crafting component is registered

CreateThread(function()
    -- wait for crafting compoinent to be registered by bridge server.lua
    while not exports['mythic-base']:FetchComponent('Crafting') do
        Wait(100)
    end

    local Crafting = exports['mythic-base']:FetchComponent('Crafting')
    local CraftingTables = lib.load('data.mythic-crafting.crafting_config')
    local schematics = lib.load('data.mythic-crafting.schematic_config')

    if CraftingTables then
        for k, bench in ipairs(CraftingTables) do
            local id = ('crafting-%s'):format(k)
            Crafting:RegisterBench(
                id,
                bench.label,
                bench.targetConfig,
                bench.location,
                bench.restriction,
                bench.recipes,
                false
            )
        end
        print(('^2[mythic-crafting-bridge] Registered %s crafting benches^0'):format(#CraftingTables))
    end

    -- load schematics 
    if schematics then
        local schematicRecipes = {}
        for schematicItem, data in pairs(schematics) do
            local recipe = table.clone(data)
            recipe.metadata = recipe.metadata or {}
            recipe.metadata.schematic = schematicItem
            recipe.metadata.locked = true -- locked by default; unlocked per-player via item use
            schematicRecipes[#schematicRecipes+1] = recipe
        end

        if #schematicRecipes > 0 then
            Crafting:RegisterBench(
                'crafting-schematics',
                'Schematics',
                nil, nil, nil,
                schematicRecipes,
                true
            )
            print(('^2[mythic-crafting-bridge] Registered %s schematic recipes^0'):format(#schematicRecipes))
        end
    end
end)