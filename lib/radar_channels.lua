local M = {}

local function build(force)
    local by_key = {}

    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{type = "radar", force = force}) do
            if entity.status == defines.entity_status.no_power then goto continue end
            local behavior = entity.get_control_behavior()
            if not behavior then goto continue end
            if behavior.mode ~= defines.control_behavior.radar.mode.universe then goto continue end
            local channel = behavior.universe_channel
            if not channel then goto continue end
            local sig_type = channel.type or "item"
            local sig_quality = channel.quality or "normal"
            local key = sig_type .. ":" .. channel.name .. ":" .. sig_quality
            by_key[key] = by_key[key] or {
                signal = {type = sig_type, name = channel.name, quality = sig_quality},
                entities = {},
            }
            table.insert(by_key[key].entities, entity)
            ::continue::
        end
    end

    local result = {}
    for _, entry in pairs(by_key) do
        table.insert(result, entry)
    end
    table.sort(result, function(a, b)
        local ka = a.signal.type .. a.signal.name .. a.signal.quality
        local kb = b.signal.type .. b.signal.name .. b.signal.quality
        return ka < kb
    end)

    return result
end

function M.get(force)
    return build(force)
end

return M
