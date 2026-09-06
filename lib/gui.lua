local radar_channels = require("lib.radar_channels")
local Channels = require("lib.channels")
local Appearance = require("lib.appearance")

local M = {}

local WINDOW_NAME = "radar-channels-window"
local CAMERA_NAME = "radar-channels-camera"
local CLOSE_BUTTON_NAME = "radar-channels-close"
local RADAR_SLOT_NAME = "radar-channels-radar-slot"
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

--- Recursively builds a LuaGuiElement tree from `def` (a LuaGuiElement.add_param
--- plus optional style_mods/elem_mods and array-part children), mirroring
--- flib.gui.add's (elems, element) contract: elems collects every named
--- descendant so callers can look them up without walking the tree by hand.
local function gui_add(parent, def)
    local style_mods = def.style_mods
    local elem_mods = def.elem_mods
    def.style_mods = nil
    def.elem_mods = nil

    local children = {}
    for i, child in ipairs(def) do
        children[i] = child
        def[i] = nil
    end

    local element = parent.add(def)

    if style_mods then
        for key, value in pairs(style_mods) do
            element.style[key] = value
        end
    end
    if elem_mods then
        for key, value in pairs(elem_mods) do
            element[key] = value
        end
    end

    local elems = {}
    if element.name and element.name ~= "" then
        elems[element.name] = element
    end
    for _, child in ipairs(children) do
        local child_elems = gui_add(element, child)
        for name, child_element in pairs(child_elems) do
            elems[name] = child_element
        end
    end

    return elems, element
end

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

--- Wire to defines.events.on_gui_click.
function M.on_click(e)
    if e.element.name == CLOSE_BUTTON_NAME then
        on_close_click(e)
    elseif e.element.name == RADAR_SLOT_NAME then
        on_radar_click(e)
    end
end

--- Wire to defines.events.on_gui_hover.
function M.on_hover(e)
    if e.element.name == RADAR_SLOT_NAME then
        on_radar_hover(e)
    end
end

--- Wire to defines.events.on_gui_leave.
function M.on_leave(e)
    if e.element.name == RADAR_SLOT_NAME then
        on_radar_leave(e)
    end
end

--- Wire to defines.events.on_gui_closed.
function M.on_closed(e)
    -- e.element is nil when a non-custom-GUI window closes (inventory,
    -- equipment grid, etc.) -- distinguished only by e.gui_type there.
    if e.element and e.element.name == WINDOW_NAME then
        on_window_closed(e)
    end
end

destroy_camera = function(player)
    local cam = player.gui.screen[CAMERA_NAME]
    if cam then cam.destroy() end
end

show_camera = function(player, tags)
    destroy_camera(player)
    local color = Appearance.quality_color(tags.quality_name)

    local _, cam_frame = gui_add(player.gui.screen, {
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

    local _, titlebar = gui_add(cam_frame, {
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

    gui_add(cam_frame, {
        type = "camera",
        position = {x = tags.x, y = tags.y},
        surface_index = tags.surface_index,
        zoom = CAMERA_ZOOM,
        style_mods = {width = CAMERA_WIDTH, height = CAMERA_HEIGHT},
    })
end

local function add_radar_cell(parent, entities)
    local _, scroll = gui_add(parent, {
        type = "scroll-pane",
        direction = "horizontal",
        style = "radar_channels_radar_scroll",
        style_mods = {width = RADAR_COLS * SLOT_SIZE},
    })

    local _, flow = gui_add(scroll, {type = "flow", direction = "horizontal"})

    for _, entity in ipairs(entities) do
        local sprite_path = Appearance.planet_sprite(entity.surface)
        local cell_def = {
            type = "flow",
            direction = "vertical",
            style_mods = {vertical_spacing = 0, size = SLOT_SIZE},
            {
                type = "sprite-button",
                name = RADAR_SLOT_NAME,
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
            },
        }
        if sprite_path then
            cell_def[#cell_def + 1] = {
                type = "sprite",
                sprite = sprite_path,
                -- resize_to_sprite defaults to true, which makes the widget
                -- snap to the icon's native size and ignore style.size below.
                elem_mods = {resize_to_sprite = false},
                style_mods = {
                    size = PLANET_ICON_SIZE,
                    stretch_image_to_widget_size = true,
                    top_margin = -SLOT_SIZE,
                    bottom_margin = -PLANET_ICON_SIZE,
                    left_margin = 2,
                },
            }
        end
        gui_add(flow, cell_def)
    end
end

local function build_gui(player)
    local channels = radar_channels.get(player.force)

    local elems, window = gui_add(player.gui.screen, {
        type = "frame",
        name = WINDOW_NAME,
        direction = "vertical",
        style_mods = {minimal_width = MAIN_WIDTH},
        {
            type = "flow",
            direction = "horizontal",
            drag_target = WINDOW_NAME,
            {type = "label", style = "frame_title", caption = {"gui.radar-channels-title"}, ignored_by_interaction = true},
            {type = "empty-widget", style = "draggable_space_header", drag_target = WINDOW_NAME, style_mods = {horizontally_stretchable = true, right_margin = 4}},
            {
                type = "sprite-button",
                name = CLOSE_BUTTON_NAME,
                style = "frame_action_button",
                sprite = "utility/close",
                hovered_sprite = "utility/close_black",
                clicked_sprite = "utility/close_black",
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
            sprite = Channels.sprite(entry.signal),
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
