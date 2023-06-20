local basalt = require("basalt")

local CHANNEL = 501
local USER = "Remiwi"

local SERVER_CHANNEL = 500
local modem = peripheral.wrap("back")
modem.open(CHANNEL)

function MakeRequest(method)
    modem.transmit(SERVER_CHANNEL, CHANNEL, { player = USER, method = method })
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == CHANNEL

    if (tostring(type(message)) ~= "table") or (message == nil) then
        basalt.debug(tostring(type(message)))
        return nil
    end

    return message
end

function InitLongList(long_list, entries)
    long_list:clear()

    local file = fs.open("cobblemons.txt", "r")
    local text = file.readAll()
    file.close()

    local lines = StringSplit(text, "\n")
    for _, line in pairs(lines) do
        local linedata = StringSplit(line, ";")
        local number, name = linedata[1], linedata[2]

        local item_text = string.format("%04d %s", tonumber(number), name)
        item_text = item_text .. string.rep(" ", 22 - string.len(item_text))

        if (entries ~= nil) and (entries[name] ~= nil) then
            if entries[name].sh_caught then
                item_text = item_text .. "!"
            elseif entries[name].caught then
                item_text = item_text .. "X"
            end

            if entries[name].sh_seen then
                item_text = item_text .. "!"
            elseif entries[name].seen then
                item_text = item_text .. "X"
            end
        end

        long_list:addItem(item_text, colors.black, colors.white)
    end
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

local main = basalt.createFrame()
    :setBackground(colors.red)

local pokedex_label = main
    :addLabel()
    :setText("Pokedex")
    :setFontSize(2)
    :setPosition(4, 2)

local status_label = main
    :addLabel()
    :setText("Status: ")
    :setPosition(4, 7)
    :setSize(20, 1)
    :setBackground(colors.cyan)

local scanButton = main
    :addButton()
    :setPosition(2, 9)
    :setSize(24, 5)
    :setText("Scan")
    :setBackground(colors.cyan)
    :onClick(
        function()
            status_label:setText("Status: Scanning...")
            basalt:update()
            local response = MakeRequest("pokedex/scan")

            if (response == nil) or (not response.pokemon_found) then
                status_label:setText("Status: No pokemon")
                return
            end

            status_label:setText("Status: Found " .. response.name)
            basalt.debug("Status: Found " .. response.name)
        end)

local pokedex_list = basalt.createFrame()
    :setBackground(colors.red)

local stats = pokedex_list
    :addList()
    :setSize(24, 6)
    :setPosition(2, 2)
    :addItem("", colors.black)
    :addItem(" Seen:      ...", colors.black, colors.white)
    :addItem("   Shinies: ...", colors.black, colors.white)
    :addItem(" Caught:    ...", colors.black, colors.white)
    :addItem("   Shinies: ...", colors.black, colors.white)
    :addItem("", colors.black)

local long_list = pokedex_list
    :addList()
    :setScrollable(true)
    :setSize(24, 11)
    :setPosition(2, 9)

InitLongList(long_list, nil)

local listButton = main
    :addButton()
    :setPosition(2, 15)
    :setSize(24, 5)
    :setText("List")
    :setBackground(colors.green)
    :onClick(
        function()
            main:hide()
            pokedex_list:show()
            basalt:update()

            local response = MakeRequest("pokedex/playerdata")
            if response == nil then
                return
            end

            local file = fs.open("cobblemons.txt", "r")
            local filetext = file.readAll()
            file.close()
            local num_mons = #(StringSplit(filetext, "\n"))


            stats:editItem(2,
                string.format(" Seen:      %04d   %03d%s ", response.seen, 100 * response.seen / num_mons, "%"),
                colors.black, colors.white)
            stats:editItem(3,
                string.format("   Shinies: %04d   %03d%s ", response.sh_seen, 100 * response.sh_seen / num_mons, "%"),
                colors.black, colors.white)
            stats:editItem(4,
                string.format(" Caught:    %04d   %03d%s ", response.caught, 100 * response.caught / num_mons, "%"),
                colors.black, colors.white)
            stats:editItem(5,
                string.format("   Shinies: %04d   %03d%s ", response.sh_caught, 100 * response.sh_caught / num_mons, "%"),
                colors.black, colors.white)

            InitLongList(long_list, response.entries)
        end)

basalt.autoUpdate()
