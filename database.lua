local M = {}

local database

--- Retrieves the amount of times the `UpdateEntry` function has been called since the start of this database
---
---@return integer
function M.GetUpdateCount()
    return database.num_updates
end

--- Loads a database given by the filename
---
--- Note: filename should end in `.db`, not `.db1`
---
--- Returns `true` if database could be loaded from file given, false otherwise. Also returns string explaining error
---
---@param filename string
---@param create_if_needed? boolean
---@return boolean, string|nil
function M.LoadData(filename, create_if_needed)
    create_if_needed = create_if_needed or false

    -- If neither exists, there is no db to load
    if (not fs.exists(filename)) and (not fs.exists(filename .. "1")) then
        if create_if_needed then
            CreateDatabaseFiles(filename)
        end
        return false, string.format("%s and %s could not be found", filename, filename .. "1")
    end

    -- If .db1 exists and it's contents are valid, then we should use those because .db could be out of data due to abrupt termination
    if LoadFromFile(filename .. "1") then
        return true
    end

    -- .db1 exists but couldn't be loaded from, and .db exists. .db1 being invalid implies that .db is valid, so we can load .db
    if LoadFromFile(filename) then
        return true
    end

    -- If for some reason both exist and neither file can be used, an unknown error is ocurring. Probably both files are corrupt?
    return false, "Unknown error loading file " .. filename
end

--- Creates `.db` and `.db1` files with empty database
---
---@param filename string
---@return nil
function CreateDatabaseFiles(filename)
    database = { num_updates = 0, data = {} }
    local file_contents = textutils.serialise(database, { compact = true })

    local file = fs.open(filename, "w")
    file.write(file_contents)
    file.close()

    file = fs.open(filename .. "1", "w")
    file.write(file_contents)
    file.close()
end

--- Attempts to load the data stored in the file `filename` as the database
---
--- Returns `false` if the file does not exist or if the data in the file is invalid
---
---@param filename string
---@return boolean
function LoadFromFile(filename)
    if not fs.exists(filename) then return false end

    local file = fs.open(filename, "r")
    local contents = file.readAll()
    file.close()

    local loaded_data = textutils.unserialise(contents)
    if loaded_data == nil then return false end

    database = loaded_data
    return true
end

--- Saves data to the file specified to permit loading in future
---
--- Saved to two files to ensure protection against abrupt exiting in the middle of saving to a file. Note that, in that event, modifications since the previous save will be lost.
---
---@param filename string
---@return nil
function M.SaveData(filename)
    local serialized_db = textutils.serialise(database, { compact = true })

    local file = fs.open(filename .. "1", "w")
    file.write(serialized_db)
    file.close()

    file = fs.open(filename, "w")
    file.write(serialized_db)
    file.close()
end

--- Saves backup of data to the file specified
---
--- Note: Do not include file extension in `filename`, it will be added automatically
---
---@param filename string
---@return nil
function M.BackupData(filename)
    local serialized_db = textutils.serialise(database, { compact = true })
    local real_filename = filename .. tostring(database.num_updates) .. ".db"

    local file = fs.open(real_filename, "w")
    file.write(serialized_db)
    file.close()
end

--- Updates the pokedex of `player` according to `pokemon data`
---
---@param player_name string
---@param pokemon_data table
---@param backup_frequency? integer
---@param backup_filename? string
---@return nil
function M.UpdateEntry(player_name, pokemon_data, backup_frequency, backup_filename)
    if database.data[player_name] == nil then
        database.data[player_name] = {}
    end
    local player_pokedex = database.data[player_name]

    if player_pokedex[pokemon_data.name] == nil then
        player_pokedex[pokemon_data.name] = {
            seen = true,
            caught = false,
            sh_seen = false,
            sh_caught = false,
        }
    end

    if pokemon_data.caught then
        player_pokedex[pokemon_data.name].caught = true
    end
    if pokemon_data.shiny then
        player_pokedex[pokemon_data.name].sh_seen = true
    end
    if pokemon_data.shiny and pokemon_data.caught then
        player_pokedex[pokemon_data.name].sh_caught = true
    end

    database.num_updates = database.num_updates + 1
    if (backup_frequency == nil) or (backup_filename == nil) or (backup_frequency < 1) then
        return
    end
    if database.num_updates % backup_frequency == 0 then
        M.BackupData(backup_filename)
    end
end

--- Retries table of all pokedex entries for the given player
---
---@param player_name string
---@return table
function M.GetEntries(player_name)
    return textutils.unserialise(textutils.serialise(database.data[player_name]))
end

return M
