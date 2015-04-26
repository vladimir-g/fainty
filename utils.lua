-----------------------------------------------
-- Fainty widgets for awesome window manager --
-----------------------------------------------
-- Copyright (c) 2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local pairs = pairs

-- Python-like string interpolation
-- From lua wiki: http://lua-users.org/wiki/StringInterpolation
function interp(s, tab)
   return (
      s:gsub('%%%((%a%w*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
             function(k, fmt) return tab[k] and ("%"..fmt):format(tab[k]) or
                '%('..k..')'..fmt end))
end
getmetatable("").__mod = interp

-- Trim spaces from string ends
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Merge settings table with defaults. Doesn't work with subtables and
-- modifies defaults table.
function merge_settings(args, defaults)
   for k,v in pairs(args) do
      defaults[k] = v
   end
   return defaults
end

return {
   utils = utils,
   trim = trim,
   merge_settings = merge_settings
}
