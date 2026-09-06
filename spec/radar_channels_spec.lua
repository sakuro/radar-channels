local RadarChannels = require("lib.radar_channels")

local function entity(opts)
  return {
    status = opts.status or "powered",
    get_control_behavior = function() return opts.behavior end,
  }
end

local function surface_with(entities)
  return {
    find_entities_filtered = function() return entities end,
  }
end

describe("RadarChannels.get", function()
  before_each(function()
    _G.defines = {
      entity_status = {no_power = "no_power"},
      control_behavior = {radar = {mode = {universe = "universe"}}},
    }
  end)

  it("includes a powered radar in universe mode with a channel set", function()
    _G.game = {surfaces = {surface_with({
      entity{behavior = {mode = "universe", universe_channel = {type = "item", name = "iron-plate", quality = "normal"}}},
    })}}

    local result = RadarChannels.get("force")

    assert.are.equal(1, #result)
    assert.are.same({type = "item", name = "iron-plate", quality = "normal"}, result[1].signal)
  end)

  it("excludes an unpowered radar", function()
    _G.game = {surfaces = {surface_with({
      entity{
        status = "no_power",
        behavior = {mode = "universe", universe_channel = {type = "item", name = "iron-plate", quality = "normal"}},
      },
    })}}

    assert.are.same({}, RadarChannels.get("force"))
  end)

  it("excludes a radar with no control behavior", function()
    _G.game = {surfaces = {surface_with({entity{behavior = nil}})}}

    assert.are.same({}, RadarChannels.get("force"))
  end)

  it("excludes a radar not in universe mode", function()
    _G.game = {surfaces = {surface_with({
      entity{behavior = {mode = "sector", universe_channel = {type = "item", name = "iron-plate"}}},
    })}}

    assert.are.same({}, RadarChannels.get("force"))
  end)

  it("excludes a radar with no channel set", function()
    _G.game = {surfaces = {surface_with({
      entity{behavior = {mode = "universe", universe_channel = nil}},
    })}}

    assert.are.same({}, RadarChannels.get("force"))
  end)

  it("defaults channel type to item and quality to normal when absent", function()
    _G.game = {surfaces = {surface_with({
      entity{behavior = {mode = "universe", universe_channel = {name = "signal-A"}}},
    })}}

    local result = RadarChannels.get("force")

    assert.are.same({type = "item", name = "signal-A", quality = "normal"}, result[1].signal)
  end)

  it("groups radars from multiple surfaces sharing the same channel", function()
    local channel = {type = "item", name = "iron-plate", quality = "normal"}
    _G.game = {surfaces = {
      surface_with({entity{behavior = {mode = "universe", universe_channel = channel}}}),
      surface_with({entity{behavior = {mode = "universe", universe_channel = channel}}}),
    }}

    local result = RadarChannels.get("force")

    assert.are.equal(1, #result)
    assert.are.equal(2, #result[1].entities)
  end)
end)
