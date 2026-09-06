local gui = require("lib.gui")

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= "radar-channels" then return end
    gui.toggle(game.get_player(event.player_index))
end)

script.on_event("radar-channels-toggle", function(event)
    gui.toggle(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_click, gui.on_click)
script.on_event(defines.events.on_gui_hover, gui.on_hover)
script.on_event(defines.events.on_gui_leave, gui.on_leave)
script.on_event(defines.events.on_gui_closed, gui.on_closed)
