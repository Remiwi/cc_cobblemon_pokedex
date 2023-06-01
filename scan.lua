local M = {}

--- Performs callback at every step until distance is reached or until callback returns true.
--- Preamble should indicate where to execute commands and relative to whom.
--- Callback should take in a preamble as well.
--- Callback should return a boolean to indicate whether or not to continue the raycast,
--- and a table with any relevant data.
---
--- @param preamble    string
--- @param callback    fun(preamble: string): boolean, table|nil
--- @param distance    number
--- @param step        number
--- @return boolean, table|nil
function Raycast(preamble, callback, distance, step)
    local pos = "execute positioned ^ ^ ^%.2f run "
    for i = 0, distance, step do
        local pre = preamble .. string.format(pos, i)
        local stop, data = callback(pre)
        if stop then
            return true, data
        end
    end
    return false, nil
end

--- Returns a callback function that checks if the entity is within the given radius,
--- and if so, returns the data at the given path.
---
--- @param entity_type    string
--- @param radius         number
--- @param data_path?     string
--- @return fun(preamble: string): boolean, table|nil
function FindEntityFactory(entity_type, radius, data_path)
    local command = string.format("data get entity @e[type=%s,limit=1,distance=..%.2f]", entity_type, radius)
    if data_path ~= "" then
        command = command .. " " .. data_path
    end

    return function(preamble)
        preamble = preamble or ""

        local found, data, _ = commands.exec(preamble .. command)
        if found then
            return true, data
        end
        return false, nil
    end
end

--- Scans for pokemon in front of the player.
---
--- @param player_name    string
--- @return table
function M.ScanForPokemon(player_name)
    local success, data = Raycast(
        string.format("execute as %s at @s anchored eyes run ", player_name),
        FindEntityFactory("cobblemon:pokemon", 1, "Pokemon.Species"),
        5, 0.5
    )
    if not success or data == nil then
        print("No pokemon found")
        return { pokemon_found = false }
    end

    local pokemon_data = {
        pokemon_found = true,
        name = StringSplit(data[1])[1],
    }
    return pokemon_data
end

--- Summons a particle at a given point.
---
--- @param preamble    string
--- @return false, nil
function ParticleSpawn(preamble)
    local command = preamble .. "particle minecraft:dripping_dripstone_lava ~ ~ ~ 0.1 0.1 0.1 0 1"
    commands.exec(command)
    return false, nil
end

--- Splits a string by the given separator.
---
--- @param inputstr    string
--- @param sep?        string
--- @return table
function StringSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return M
