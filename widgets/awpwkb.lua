------------------
-- Awpwkb widget--
------------------
-- Copyright (c) 2017 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details
local wibox = require("wibox")
local awful = require('awful')
local utils = require("fainty.utils")
local setmetatable = setmetatable
local pairs = pairs

local AwpwkbWidget = { mt = {} }

-- Refresh widget on layout change
function AwpwkbWidget:on_layout_change(kb, layout)
   local name = layout.name
   -- Replace name with custom for some layouts
   if self.settings.process_name then
      name = self.settings.process_name(name)
   end
   self:set_markup(self.settings.fmt % {
                      name = name,
                      layout_name = layout.name,
                      layout_index = layout.idx
   })
end

-- Create widget
-- it is better to initialize awpwkb before
local function new(args)
   settings = utils.merge_settings(
      args or {},
      {
         fmt = ' <b>[%(name)s]</b> ',
         menu_theme = { width = 80, height = 15 },
         bind_buttons = true
      }
   )

   local obj = wibox.widget.textbox()
   for k, v in pairs(AwpwkbWidget) do
      obj[k] = v
   end
   obj.settings = settings

   kb = awpwkb.get()
   local menu_layouts = {}
   for i, l in pairs(kb:get_layouts()) do
      label = l.name
      if settings.process_name then
         label = settings.process_name(label)
      end
      menu_layouts[i] = { label, function () kb:set_layout(l.name) end }
   end
   obj.layout_menu = awful.menu({ theme = menu_theme,
                                  items = menu_layouts })

   -- Bind buttons
   if settings.bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.util.table.join(
               awful.button({ }, 1, function() kb:set_next_layout() end),
               awful.button({ }, 2, function() kb:set_prev_layout() end),
               awful.button({ }, 3, function() obj.layout_menu:toggle() end)
            )
      ))
   end

   -- Refresh widget on layout change
   kb:connect_signal("on_layout_change", function (...) obj:on_layout_change(...) end)

   return obj
end

function AwpwkbWidget.mt:__call(...)
   return new(...)
end

return setmetatable(AwpwkbWidget, AwpwkbWidget.mt)
