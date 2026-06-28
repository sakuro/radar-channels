local flib_gui = require("__flib__.gui")
local radar_channels = require("lib.radar_channels")

local M = {}

local WINDOW_NAME = "radar-channels-window"
local CAMERA_NAME = "radar-channels-camera"
local CAMERA_WIDTH = 480
local CAMERA_HEIGHT = 270
local CAMERA_ZOOM = 0.5
local MAX_VISIBLE_ROWS = 10
local ROW_HEIGHT = 40
local SLOT_SIZE = 40
local RADAR_COLS = 8
local MAIN_WIDTH = RADAR_COLS * SLOT_SIZE + 160
local PLANET_ICON_SIZE = 16

local destroy_camera, show_camera, close_gui, open_remote_view

local function on_close_click(e)
    close_gui(game.get_player(e.player_index))
end

local function on_window_closed(e)
    close_gui(game.get_player(e.player_index))
end

local function on_radar_click(e)
    open_remote_view(game.get_player(e.player_index), e.element.tags)
end

local function on_radar_hover(e)
    show_camera(game.get_player(e.player_index), e.element.tags)
end

local function on_radar_leave(e)
    destroy_camera(game.get_player(e.player_index))
end

flib_gui.add_handlers({
    on_close_click   = on_close_click,
    on_window_closed = on_window_closed,
    on_radar_click   = on_radar_click,
    on_radar_hover   = on_radar_hover,
    on_radar_leave   = on_radar_leave,
})

local function signal_sprite(signal)
    if signal.type == "virtual" then
        return "virtual-signal/" .. signal.name
    end
    return signal.type .. "/" .. signal.name
end

local function quality_color(quality_name)
    local proto = prototypes.quality and prototypes.quality[quality_name]
    return (proto and proto.color) or {r = 1, g = 1, b = 1}
end

local function planet_sprite(surface)
    local ok, planet = pcall(function() return surface.planet end)
    if not ok or not planet then return nil end
    local ok2, name = pcall(function() return planet.prototype.name end)
    if not ok2 or not name then return nil end
    local path = "space-location/" .. name
    local ok3, valid = pcall(helpers.is_valid_sprite_path, path)
    return (ok3 and valid) and path or nil
end

destroy_camera = function(player)
    local cam = player.gui.screen[CAMERA_NAME]
    if cam then cam.destroy() end
end

show_camera = function(player, tags)
    destroy_camera(player)
    local color = quality_color(tags.quality_name)

    local _, cam_frame = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = CAMERA_NAME,
        direction = "vertical",
        ignored_by_interaction = true,
    })

    local main = player.gui.screen[WINDOW_NAME]
    if main then
        local loc = main.location
        cam_frame.location = {x = loc.x + MAIN_WIDTH + 8, y = loc.y}
    else
        cam_frame.auto_center = true
    end

    local _, titlebar = flib_gui.add(cam_frame, {
        type = "flow",
        direction = "horizontal",
        style_mods = {vertical_align = "center"},
        {
            type = "sprite-button",
            style = "slot_button",
            sprite = "entity/radar",
            quality = tags.quality_name,
            ignored_by_interaction = true,
            style_mods = {size = 28},
        },
        {
            type = "label",
            style = "frame_title",
            caption = {"entity-name." .. tags.entity_name},
            style_mods = {font_color = color},
        },
    })
    if tags.backer_name ~= "" then
        local backer = titlebar.add{type = "label", style = "frame_title", caption = tags.backer_name}
        backer.style.font_color = color
    end

    flib_gui.add(cam_frame, {
        type = "camera",
        position = {x = tags.x, y = tags.y},
        surface_index = tags.surface_index,
        zoom = CAMERA_ZOOM,
        style_mods = {width = CAMERA_WIDTH, height = CAMERA_HEIGHT},
    })
end

local function add_radar_cell(parent, entities)
    local _, scroll = flib_gui.add(parent, {
        type = "scroll-pane",
        direction = "horizontal",
        style = "radar_channels_radar_scroll",
        style_mods = {width = RADAR_COLS * SLOT_SIZE},
    })

    local _, flow = flib_gui.add(scroll, {type = "flow", direction = "horizontal"})

    for _, entity in ipairs(entities) do
        local sprite_path = planet_sprite(entity.surface)
        local cell_def = {
            type = "flow",
            direction = "vertical",
            style_mods = {vertical_spacing = 0, size = SLOT_SIZE},
            {
                type = "sprite-button",
                style = "slot_button",
                sprite = "entity/radar",
                quality = entity.quality.name,
                tooltip = entity.localised_name,
                tags = {
                    surface_index = entity.surface_index,
                    x = entity.position.x,
                    y = entity.position.y,
                    entity_name = entity.name,
                    backer_name = entity.backer_name or "",
                    quality_name = entity.quality.name,
                },
                elem_mods = {raise_hover_events = true},
                handler = {
                    [defines.events.on_gui_click] = on_radar_click,
                    [defines.events.on_gui_hover] = on_radar_hover,
                    [defines.events.on_gui_leave] = on_radar_leave,
                },
            },
        }
        if sprite_path then
            cell_def[#cell_def + 1] = {
                type = "sprite",
                sprite = sprite_path,
                style_mods = {
                    size = PLANET_ICON_SIZE,
                    top_margin = -SLOT_SIZE,
                    bottom_margin = -PLANET_ICON_SIZE,
                    left_margin = 2,
                },
            }
        end
        flib_gui.add(flow, cell_def)
    end
end

local function build_gui(player)
    local channels = radar_channels.get(player.force)

    local elems, window = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = WINDOW_NAME,
        direction = "vertical",
        style_mods = {minimal_width = MAIN_WIDTH},
        handler = {[defines.events.on_gui_closed] = on_window_closed},
        {
            type = "flow",
            direction = "horizontal",
            drag_target = WINDOW_NAME,
            {type = "label", style = "frame_title", caption = {"gui.radar-channels-title"}, ignored_by_interaction = true},
            {type = "empty-widget", style = "draggable_space_header", drag_target = WINDOW_NAME, style_mods = {horizontally_stretchable = true, right_margin = 4}},
            {
                type = "sprite-button",
                style = "frame_action_button",
                sprite = "utility/close",
                hovered_sprite = "utility/close_black",
                clicked_sprite = "utility/close_black",
                handler = on_close_click,
            },
        },
        {
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical",
            {
                type = "scroll-pane",
                name = "main_scroll",
                direction = "vertical",
                style = "radar_channels_main_scroll",
            },
        },
    })
    window.auto_center = true

    local scroll = elems.main_scroll
    if #channels == 0 then
        local label = scroll.add{type = "label", caption = {"gui.radar-channels-no-radars"}}
        label.style.top_padding = 8
        label.style.bottom_padding = 8
        label.style.left_padding = 8
        label.style.right_padding = 8
        return
    end

    if #channels > MAX_VISIBLE_ROWS then
        scroll.style.maximal_height = MAX_VISIBLE_ROWS * ROW_HEIGHT
    end

    local t = scroll.add{type = "table", column_count = 3}
    t.style.column_alignments[1] = "center"
    t.style.column_alignments[2] = "right"
    t.style.vertical_spacing = 4
    t.draw_horizontal_line_after_headers = true

    t.add{type = "label", style = "bold_label", caption = {"gui.radar-channels-channel"}}
    t.add{type = "label", style = "bold_label", caption = {"gui.radar-channels-count"}}
    t.add{type = "label", style = "bold_label", caption = {"", {"gui.radar-channels-radars"}, " (", {"gui-control-behavior.mode-of-operation"}, ": ", {"gui-control-behavior-modes-guis.radar-universe"}, ")"}}

    for _, entry in ipairs(channels) do
        local sig_cell = t.add{type = "flow", direction = "horizontal"}
        sig_cell.style.vertical_align = "center"
        local sig_btn = sig_cell.add{
            type = "sprite-button",
            style = "slot_button",
            sprite = signal_sprite(entry.signal),
        }
        if entry.signal.quality ~= "normal" then
            sig_btn.quality = entry.signal.quality
        end

        t.add{type = "label", caption = tostring(#entry.entities)}
        add_radar_cell(t, entry.entities)
    end
end

close_gui = function(player)
    destroy_camera(player)
    local window = player.gui.screen[WINDOW_NAME]
    if window then window.destroy() end
end

local function open_gui(player)
    if player.gui.screen[WINDOW_NAME] then return end
    build_gui(player)
    player.opened = player.gui.screen[WINDOW_NAME]
end

local function toggle_gui(player)
    if player.gui.screen[WINDOW_NAME] then
        close_gui(player)
    else
        open_gui(player)
    end
end

open_remote_view = function(player, tags)
    close_gui(player)
    player.set_controller{
        type = defines.controllers.remote,
        position = {x = tags.x, y = tags.y},
        surface = game.surfaces[tags.surface_index],
    }
end

M.toggle = toggle_gui

return M
