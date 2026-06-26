local gui = require("lib.gui")
local flib_gui = require("__flib__.gui")

flib_gui.handle_events()

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= "radar-channels" then return end
    gui.toggle(game.get_player(event.player_index))
end)

script.on_event("radar-channels-toggle", function(event)
    gui.toggle(game.get_player(event.player_index))
end)
