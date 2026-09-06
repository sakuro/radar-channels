local Channels = require("lib.channels")

describe("Channels.sprite", function()
  it("uses the virtual-signal sprite group for a virtual signal", function()
    assert.are.equal("virtual-signal/signal-A", Channels.sprite({type = "virtual", name = "signal-A"}))
  end)

  it("uses the signal's own type as the sprite group for a non-virtual signal", function()
    assert.are.equal("item/iron-plate", Channels.sprite({type = "item", name = "iron-plate"}))
  end)
end)

describe("Channels.group", function()
  it("returns an empty list for no records", function()
    assert.are.same({}, Channels.group({}))
  end)

  it("puts entities with the same signal identity into one group", function()
    local signal = {type = "item", name = "iron-plate", quality = "normal"}
    local result = Channels.group({
      {signal = signal, entity = "a"},
      {signal = signal, entity = "b"},
    })

    assert.are.equal(1, #result)
    assert.are.same(signal, result[1].signal)
    assert.are.same({"a", "b"}, result[1].entities)
  end)

  it("treats a different quality as a distinct group even with the same type and name", function()
    local result = Channels.group({
      {signal = {type = "item", name = "iron-plate", quality = "normal"}, entity = "a"},
      {signal = {type = "item", name = "iron-plate", quality = "legendary"}, entity = "b"},
    })

    assert.are.equal(2, #result)
  end)

  it("sorts groups by signal type, then name, then quality", function()
    local result = Channels.group({
      {signal = {type = "item", name = "iron-plate", quality = "normal"}, entity = "a"},
      {signal = {type = "fluid", name = "water", quality = "normal"}, entity = "b"},
      {signal = {type = "item", name = "copper-plate", quality = "normal"}, entity = "c"},
    })

    local order = {}
    for _, entry in ipairs(result) do
      order[#order + 1] = entry.signal.name
    end
    assert.are.same({"water", "copper-plate", "iron-plate"}, order)
  end)
end)
