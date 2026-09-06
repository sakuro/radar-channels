local Appearance = require("lib.appearance")

describe("Appearance.quality_color", function()
  before_each(function()
    _G.prototypes = {quality = {}}
  end)

  it("returns the quality prototype's color when it exists", function()
    _G.prototypes.quality.legendary = {color = {r = 1, g = 0.5, b = 0}}
    assert.are.same({r = 1, g = 0.5, b = 0}, Appearance.quality_color("legendary"))
  end)

  it("falls back to white when the quality prototype is missing", function()
    assert.are.same({r = 1, g = 1, b = 1}, Appearance.quality_color("unknown"))
  end)
end)

describe("Appearance.planet_sprite", function()
  before_each(function()
    _G.helpers = {is_valid_sprite_path = function() return true end}
  end)

  it("returns nil when the surface has no planet", function()
    local surface = {planet = nil}
    assert.is_nil(Appearance.planet_sprite(surface))
  end)

  it("returns the space-location sprite path for the surface's planet", function()
    local surface = {planet = {prototype = {name = "nauvis"}}}
    assert.are.equal("space-location/nauvis", Appearance.planet_sprite(surface))
  end)

  it("returns nil when the sprite path is not valid", function()
    _G.helpers.is_valid_sprite_path = function() return false end
    local surface = {planet = {prototype = {name = "nauvis"}}}
    assert.is_nil(Appearance.planet_sprite(surface))
  end)
end)
