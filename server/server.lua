local Scan = require("scan")
local Database = require("database")

local CHANNEL = 500
local DB_FILENAME = "pokedex.db"
local DB_BACKUP_FILENAME = "pokedex_backups/backup"

--- Handles incoming requests based on method and player and sends a response
--- If the request does not conform to the {player: ..., method: ...} shape, then an error string is given as a response
---
---@param modem            table
---@param request          table
---@param replyChannel     number
---@return nil
function HandleRequest(modem, request, replyChannel)
    print("Request received")

    if tostring(type(request)) ~= "table" then
        print("Request: Invalid")
        modem.transmit(replyChannel, CHANNEL, "Message must be valid table")
        return
    end

    if (request.player == nil or request.method == nil) then
        print("Request: Invalid")
        modem.transmit(replyChannel, CHANNEL, "Message must have non-nil `player` and `method` fields")
        return
    end

    if (request.method == "pokedex/scan") then
        print("Request: pokedex/scan")
        local pokemon_data = Scan.ScanForPokemon(request.player)
        modem.transmit(replyChannel, CHANNEL, pokemon_data)
        if pokemon_data.pokemon_found then
            Database.UpdateEntry(request.player, pokemon_data, 10, DB_BACKUP_FILENAME)
            Database.SaveData(DB_FILENAME)
        end
        return
    end

    if (request.method == "pokedex/playerdata") then
        print("Request: pokedex/playerdata")
        local player_data = Database.GetEntries(request.player)
        modem.transmit(replyChannel, CHANNEL, player_data)
        return
    end

    print("Request: Invalid")
    modem.transmit(replyChannel, CHANNEL, "Invalid method")
end

-- Main function
function Main()
    Database.LoadData(DB_FILENAME, true)

    local modem = peripheral.find("modem")
    modem.open(CHANNEL)
    while true do
        if os == nil then
            os = { queueEvent = function(x) end, pullEvent = function() end }
        end
        os.queueEvent("randomEvent")
        os.pullEvent()

        local channel, replyChannel, message
        repeat
            _, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
        until channel == CHANNEL

        HandleRequest(modem, message, replyChannel)
        print()
    end
end

Main()
