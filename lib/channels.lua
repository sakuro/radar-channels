local Channels = {}

--- Sprite path for a signal, e.g. "item/iron-plate" or "virtual-signal/signal-A".
function Channels.sprite(signal)
  if signal.type == "virtual" then
    return "virtual-signal/" .. signal.name
  end
  return signal.type .. "/" .. signal.name
end

local function group_key(signal)
  return signal.type .. ":" .. signal.name .. ":" .. signal.quality
end

local function sort_key(signal)
  return signal.type .. signal.name .. signal.quality
end

--- Groups `records` (each {signal = {type, name, quality}, entity = <opaque>})
--- by signal identity, returning entries {signal, entities} sorted by signal
--- type, then name, then quality. `entity` is passed through untouched, so
--- callers may pass live entities or plain stand-ins.
function Channels.group(records)
  local by_key = {}
  local result = {}
  for _, record in ipairs(records) do
    local key = group_key(record.signal)
    local entry = by_key[key]
    if not entry then
      entry = {signal = record.signal, entities = {}}
      by_key[key] = entry
      result[#result + 1] = entry
    end
    table.insert(entry.entities, record.entity)
  end
  table.sort(result, function(a, b) return sort_key(a.signal) < sort_key(b.signal) end)
  return result
end

return Channels
