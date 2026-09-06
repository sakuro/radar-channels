local Appearance = {}

--- The color associated with a quality prototype, or white when the
--- prototype doesn't exist (e.g. a quality mod was removed).
function Appearance.quality_color(quality_name)
  local proto = prototypes.quality and prototypes.quality[quality_name]
  return (proto and proto.color) or {r = 1, g = 1, b = 1}
end

--- The space-location sprite path for `surface`'s planet, or nil when the
--- surface has no planet, or its sprite isn't a valid path.
function Appearance.planet_sprite(surface)
  local ok, planet = pcall(function() return surface.planet end)
  if not ok or not planet then return nil end
  local ok2, name = pcall(function() return planet.prototype.name end)
  if not ok2 or not name then return nil end
  local path = "space-location/" .. name
  local ok3, valid = pcall(helpers.is_valid_sprite_path, path)
  return (ok3 and valid) and path or nil
end

return Appearance
