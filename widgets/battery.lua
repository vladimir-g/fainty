--------------------
-- Battery widget --
--------------------
-- Copyright (c) 2013-2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local wibox = require("wibox")
local awful = require('awful')
local naughty = require('naughty')
local utils = require("fainty.utils")
local math = math
local unpack = unpack
local setmetatable = setmetatable
local io = io
local os = os
local pairs = pairs
local table = table

local Battery = { mt = {} }

Battery.path = '/sys/class/power_supply/'

function Battery:new(bat)
   local new_instance = { name = bat, 
                          path = Battery.path .. bat .. '/' }
   setmetatable(new_instance, { __index = Battery })
   return new_instance
end

function Battery:read(val)
   local path = self.path .. val
   local fd = io.open(path, 'r')
   if not fd then
      return nil
   end
   data = fd:read('*all')
   fd:close()
   return utils.trim(data)
end

function Battery:is_present()
   local present = self:read('present')
   if present == '1' then
      return true
   else
      return false
   end
end

function Battery:status()
   local data = { status = self:read('status'),
                  percent = nil,
                  time = nil,
                  capacity = nil,
                  watt = nil }

   local current, full, rate
   data.percent = tonumber(self:read('capacity'))
   -- local rate_v = tonumber(self:read('voltage_now'))

   if self:read('energy_now') then
      current = tonumber(self:read('energy_now'))
      full = tonumber(self:read('energy_full'))
      rate = tonumber(self:read('power_now'))
   elseif self:read('charge_now') then
      current = tonumber(self:read('charge_now'))
      full = tonumber(self:read('charge_full'))
      rate = tonumber(self:read('current_now'))
   else
      return data
   end

   -- if rate ~= nil and rate_v ~= nil then
   --    data.watt = (rate * rate_v) / 1e12
   -- end

   if not data.percent then
      data.percent = math.min(math.floor(current / full * 100), 100)
   end

   local left
   if rate ~= 0 and data.status == 'Discharging' then
      left = current / rate
   elseif rate ~= 0 and data.status == 'Charging' then
      left = (full - current) / rate
   else
      left = nil
   end 

   if left then
      data.hours = math.floor(left)
      data.minutes = math.floor(60 * (left - data.hours))
      data.in_seconds = math.floor(data.hours * 3600 +
                                      (data.minutes * 60))
   else
      data.hours = nil
      data.minutes = nil
      data.in_seconds = nil
   end

   return data
end      

local BatteryWidget = { mt = {} }

function BatteryWidget:refresh()
   local bat = self.selected
   if bat == nil then
      self:set_markup(self.settings.fmt_not_present)
      return
   end

   if bat:is_present() then
      local data = bat:status()
      local fmt = self.settings.fmt_unknown
      if data.status == 'Discharging' then
         fmt = self.settings.fmt_discharging
      elseif data.status == 'Charging' then
         fmt = self.settings.fmt_charging
      end

      if (data.in_seconds and data.in_seconds < self.warning_seconds
          and data.status == 'Discharging') then
         fmt = self.settings.fmt_warning
         if self.settings.notify_warning then
            self.notif_id = naughty.notify({
                  preset = naughty.config.presets.critical,
                  timeout = 10,
                  replaces_id = self.notif_id or nil,
                  title = self.settings.notify_warning_title,
                  text = self.settings.notify_warning_text
            }).id
         end
      end

      local percent = 0
      if data.percent then
         percent = data.percent
      end

      local values = {
         name = self.selected.name,
         status = data.status,
         percent = percent or 0,
         hours = data.hours or 0,
         minutes = data.minutes or 0,
         in_seconds = data.in_seconds or 0,
         watt = data.watt or 0
      }

      self:set_markup(fmt % values)
      -- Update popup if needed
      if self.settings.show_popup then
         self.popup_box:set_markup(self.settings.popup_fmt % values)
      end

   else
      self:set_markup(self.settings.fmt_not_present)
   end
   return
end

-- Get batteries table for awful.menu
function BatteryWidget:get_menu_items()
   local battery_list = {}
   for k, v in pairs(self.batteries) do
      battery_list[k] = {
         v.name,
         function ()
            self.selected = self.batteries[k]
            self:refresh()
         end
      }
   end
   return battery_list
end


-- Create battery popup
function BatteryWidget:create_popup()
   self.popup = wibox({})
   self.popup.ontop = true
   local wgt = wibox.widget.textbox()
   local layout = wibox.layout.margin()
   layout:set_widget(wgt)
   layout:set_margins(5)
   self.popup:set_widget(layout)
   self.popup_layout = layout
   self.popup_box = wgt
end


-- Set geometry and position of info popup
function BatteryWidget:place_popup()
   -- Placement
   awful.placement.under_mouse(self.popup)
   awful.placement.no_offscreen(self.popup)
   -- Geometry
   local geom = self.popup:geometry()
   local n_w, n_h = self.popup_layout:fit(9999, 9999) -- An hack
   if geom.width ~= n_w or geom.height ~= n_h then
      self.popup:geometry({ width = n_w, height = n_h })
   end
end

-- Toggle info popup wibox visibility
function BatteryWidget:toggle_popup()
   if self.popup.visible == false then
      self:show_popup()
   else
      self:hide_popup()
   end
end

-- Show info popup
function BatteryWidget:show_popup()
   if self.popup.visible then return end
   self:refresh()
   self:place_popup()
   self.popup.visible = true
end

-- Hide info popup
function BatteryWidget:hide_popup()
   if not self.popup.visible then return end
   self.popup.visible = false
end

local function new(args)
   -- TODO: Additional battery params, voltage, etc
   args.selected = args.selected or 'BAT0'

   settings = utils.merge_settings(
      args.settings or {},
      {
         fmt_discharging = ' <span color="#F80000">↯</span>%(percent)3d% '
            .. '(%(hours)d:%(minutes)02d)', -- Red color
         fmt_charging = ' <span color="#00EE00">↯</span>%(percent)3d% ' ..
            '(%(hours)d:%(minutes)02d)', -- Green color
         fmt_unknown = ' <span color="#FFFFFF">↯</span>%(percent)3d%', -- White
         fmt_warning = ' <span color="#F80000">↯!%(percent)3d%</span>', -- Red
         fmt_not_present = ' <span color="#FFFFFF">↯</span> N/A', -- White
         popup_fmt = 'Name: %(name)s\n' ..
            'Status: %(status)s\n' ..
            'Remaining: %(percent)s%\n' ..
            'Time: %(hours)s:%(minutes)s',
         show_popup = true,
         menu_theme = { width = 120, height = 15 },
         bind_buttons = true,
         warning_seconds = 600,
         refresh_timeout = 25,
         notify_warning = true,
         notify_warning_title = 'Low battery',
         notify_warning_text = 'Less than 10 minutes remaining'
      }
   )

   local obj = wibox.widget.textbox()
   for k, v in pairs(BatteryWidget) do
      obj[k] = v
   end
   obj.settings = settings
   obj.warning_seconds = settings.warning_seconds
   -- Get battery list
   obj.batteries = {}
   obj.selected = nil
   local batlist = io.popen('ls ' .. Battery.path)
   for line in batlist:lines() do
      if line:match('^BAT%d+') then
         battery = Battery:new(line)
         if battery.name == args.selected then
            obj.selected = battery
         end
         table.insert(obj.batteries, battery)
      end
   end
   if not obj.selected and #obj.batteries ~= 0 then
      obj.selected = obj.batteries[1]
   end

   batlist:close()

   local btns = {}

   -- Popup
   if obj.settings.show_popup then
      obj:create_popup()
      if settings.bind_buttons then
         table.insert(
            btns,
            awful.button({ }, 1, function () obj:toggle_popup() end)
         )
      end
   end

   -- Add menu if there is more than one battery
   if #obj.batteries ~= 1 then
      local battery_menu = awful.menu({ items = obj:get_menu_items(),
                                        theme = settings.menu_theme })
      if settings.bind_buttons then
         table.insert(
            btns,
            awful.button({ }, 3, function () battery_menu:toggle() end)
         )
      end
   end

   if settings.bind_buttons then
      obj:buttons(unpack(btns))
   end

   obj:refresh()

   -- Set update timer
   if #obj.batteries ~= 0 then
      refresh_timer = timer({ timeout = settings.refresh_timeout })
      refresh_timer:connect_signal("timeout", function() obj:refresh() end)
      refresh_timer:start()
   end

   return obj
end

function BatteryWidget.mt:__call(...)
   return new(...)
end

return setmetatable(BatteryWidget, BatteryWidget.mt)
