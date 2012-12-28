----------------
-- Kbdd widget--
----------------
-- Copyright (c) 2012 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local wibox = require("wibox")
local awful = require('awful')
local setmetatable = setmetatable
local tonumber = tonumber
local io = io
local os = os
local pairs = pairs
local dbus = dbus
local table = table

-- Widget class
local KbddWidget = { mt = {} }

-- Send dbus command
function KbddWidget.send_command(command, capture)
   capture = capture or false
   -- Construct command
   local cmd = "dbus-send "
   if capture then
      cmd = cmd .. "--print-reply "
   end
   cmd = cmd .. "--dest=ru.gentoo.KbddService " .. 
      "/ru/gentoo/KbddService ru.gentoo.kbdd." ..
      command
   if capture then
      -- Execute command and get result
      local fd = io.popen(cmd)
      local result = fd:read("*all")
      local retcode = fd:close()
      if retcode then
         return result
      end
   else
      -- Execute command without caring about result
      os.execute(cmd)
   end
end      

-- Get table position of selected layout
function KbddWidget:get_selected_layout()
   for i, v in pairs(self.layouts) do
      if v.selected then
         return i, v
      end
   end
end

-- Set displayed layout
function KbddWidget:display(index)
   local set = false
   for i, v in pairs(self.layouts) do
      if v.index == index then
         self:set_markup(v.label)
         v.selected = true
         set = true
      elseif v.selected then
         v.selected = false
      end
   end
   if not set then
      self:set_markup(self.error_msg)
   end
end

-- Set next layout
function KbddWidget:next_layout()
   local i, selected = self:get_selected_layout()
   if i then
      local next_i = i + 1
      if next_i > # self.layouts then
         next_i = 1
      end
      local next_index = self.layouts[next_i].index
      self:set_layout(next_index)
      self:display(next_index)
   end
end

-- Set previous layout
function KbddWidget:prev_layout()
   local i, selected = self:get_selected_layout()
   if i then
      local prev_i = i - 1
      if prev_i < 1 then
         prev_i = # self.layouts
      end
      local prev_index = self.layouts[prev_i].index
      self:set_layout(prev_index)
      self:display(prev_index)
   end
end

-- Set layout by index
function KbddWidget:set_layout(index)
   self.send_command("set_layout uint32:" .. index)
end

-- D-Bus callback
function KbddWidget:dbus_callback(...)
   local data = {...}
   local index = data[2]
   self:display(index)
end   

-- Get layout table for awful.menu
function KbddWidget:get_menu_items()
   local layout_list = {}
   for i, v in pairs(self.layouts) do
      table.insert(layout_list, { v.name, 
                                  function ()
                                     self:set_layout(v.index)
                                     self:display(v.index)
                                  end,
                                  v.image })
   end
   return layout_list
end

-- Create widget
function new(layout_list, settings)
   settings = settings or {}
   local obj = wibox.widget.textbox()
   -- Put KbddWidget's methods to textbox
   for k, v in pairs(KbddWidget) do
      obj[k] = v
   end
   menu_theme = settings.menu_theme or { width = 80, height = 15 }
   obj.error_msg = settings.error_msg or '<span color="#FF0004">[#]</span>'
   obj.layouts = {}
   for k, v in pairs(layout_list) do
      table.insert(obj.layouts, { label = v.label,
                                  index = v.index,
                                  name = v.name,
                                  image = v.image,
                                  selected = false })
   end
   -- Add menu
   obj.layout_menu = awful.menu({ items = obj:get_menu_items(),
                                  theme = menu_theme })
   -- Bind buttons
   if not settings.dont_bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:next_layout() end),
            awful.button({ }, 3, function () obj.layout_menu:toggle() end),
            awful.button({ }, 4, function () obj:next_layout() end),
            awful.button({ }, 5, function () obj:prev_layout() end)
                              ))
   end
   -- Bind dbus signals
   dbus.request_name("session", "ru.gentoo.kbdd")
   dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
   dbus.connect_signal("ru.gentoo.kbdd", function (...) obj:dbus_callback(...) end)
   -- Get current layout
   local current = KbddWidget.send_command("getCurrentLayout", true)
   if current then
      obj:display(tonumber(current:match("uint32 (%d)")))
   end
   return obj
end

function KbddWidget.mt:__call(...)
   return new(...)
end

return setmetatable(KbddWidget, KbddWidget.mt)
