local styles = data.raw["gui-style"]["default"]

styles["radar_channels_main_scroll"] = {
    type = "scroll_pane_style",
    parent = "scroll_pane",
    horizontal_scroll_policy = "never",
}

styles["radar_channels_radar_scroll"] = {
    type = "scroll_pane_style",
    parent = "scroll_pane",
    horizontal_scroll_policy = "auto",
    vertical_scroll_policy = "never",
}

data:extend{
    {
        type = "custom-input",
        name = "radar-channels-toggle",
        key_sequence = "",
        action = "lua",
    },
    {
        type = "shortcut",
        name = "radar-channels",
        action = "lua",
        icon = "__radar-channels__/graphics/icons/radar-channels-x56.png",
        icon_size = 56,
        small_icon = "__radar-channels__/graphics/icons/radar-channels-x24.png",
        small_icon_size = 24,
        associated_control_input = "radar-channels-toggle",
    },
}
