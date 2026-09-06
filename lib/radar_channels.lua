local Channels = require("lib.channels")

local M = {}

local function collect(force)
    local records = {}

    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{type = "radar", force = force}) do
            if entity.status == defines.entity_status.no_power then goto continue end
            local behavior = entity.get_control_behavior()
            if not behavior then goto continue end
            if behavior.mode ~= defines.control_behavior.radar.mode.universe then goto continue end
            local channel = behavior.universe_channel
            if not channel then goto continue end
            records[#records + 1] = {
                signal = {
                    type = channel.type or "item",
                    name = channel.name,
                    quality = channel.quality or "normal",
                },
                entity = entity,
            }
            ::continue::
        end
    end

    return records
end

function M.get(force)
    return Channels.group(collect(force))
end

return M
