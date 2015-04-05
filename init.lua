-----------------------------------------------
-- Fainty widgets for awesome window manager --
-----------------------------------------------
-- Copyright (c) 2012-2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local setmetatable = setmetatable

return {
   widgets = setmetatable({}, {
         __index = function (t, k)
            return require('fainty.widgets.' .. k);
         end
   })
}
