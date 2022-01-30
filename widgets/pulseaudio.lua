-----------------------------
-- PulseAudio volume widget--
-----------------------------
-- Copyright (c) 2015-2021 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local setmetatable = setmetatable
local pairs = pairs
local timer = require("gears.timer")
local type = type
local string = string

-- Object that represents sink or source
local PulseChannel = {}

-- Crate new channel, accepts type and name or index
function PulseChannel:new(channel_type, name, max_volume)
   local new_instance = {
      channel_type = channel_type,
      name = name,
      max_volume = max_volume,
      volume = 0,
      muted = false,
      has_error = false
   }
   setmetatable(new_instance, { __index = PulseChannel })
   return new_instance
end

-- Get channel volume and muted state
function PulseChannel:update(callback)
   -- Combine both commands for one async run
   local cmd = 'LC_ALL=C pactl get-' .. self.channel_type .. '-volume ' .. self.name .. ' '
      .. '&& LC_ALL=C pactl get-' .. self.channel_type .. '-mute ' .. self.name
   local func = function (stdout)
      local got_volume = false
      local got_mute = false
      for line in stdout:gmatch("[^\n]+") do
         line:gsub('Mute:%s+(%w+)', function (status)
                      self.muted = (status == 'yes')
                      got_mute = true
         end)
         line:gsub('Volume:[^/]+/%s+(%d+)%%%s+/', function (volume)
                      self.volume = tonumber(volume)
                      got_volume = true
         end)
      end
      if not got_volume or not got_mute then
         self.has_error = true
      else
         self.has_error = false
      end

      -- Execute callback when volume and muted are updated
      if callback then
         callback()
      end
   end
   awful.spawn.easy_async_with_shell(cmd, func)
end

-- Get dafault sink or source data
function PulseChannel.get_default(channel_type)
   return '@DEFAULT_' .. string.upper(channel_type) .. '@'
end

-- Raise channel volume
function PulseChannel:raise(value)
   value = value or 1
   if self.volume + value > self.max_volume then
      value = self.max_volume - self.volume
   end
   awful.spawn("pactl set-" .. self.channel_type .. "-volume " ..
               self.name .. ' +' .. value .. '%')
   self.volume = self.volume + value
end

-- Lower channel volume
function PulseChannel:lower(value)
   value = value or 1
   if self.volume - value < 0 then
      value = self.volume
   end
   awful.spawn("pactl set-" .. self.channel_type .. "-volume " ..
               self.name .. ' -' .. value .. '%')
   self.volume = self.volume - value
end

-- Mute or unmute channel
function PulseChannel:toggle()
   awful.spawn("pactl set-" .. self.channel_type .. "-mute " ..
               self.name .. " toggle")
   self.muted = not self.muted
end

-- Widget class
local PulseAudioWidget = { mt = {} }

-- Set selected channel
-- channel_num - channel position in initially provided channel array
function PulseAudioWidget:select_channel(channel_num)
   if not channel_num then
      return self.selected
   else
      return self.channels[channel_num]
   end
end

-- Refresh channel state
function PulseAudioWidget:update(channel_num)
   local channel = self:select_channel(channel_num)
   channel.control:update(function ()
         self:refresh()
   end)
end

-- Refresh channel state
function PulseAudioWidget:refresh(channel_num)
   local channel = self:select_channel(channel_num)
   local label = ''
   if channel.control.has_error then
      self:set_markup(self.error_msg)
      if self.notify_errors then
         naughty.notify({ preset = naughty.config.presets.critical,
                          title = "Error in pulseaudio widget",
                          text = "Error while trying to run pactl" })
      end
      return
   end
   if channel.control.muted then
      label = '<span color="' .. self.color.muted .. '">'
         .. channel.icon .. '</span>'
   else
      label = '<span color="' .. self.color.unmuted .. '">'
         .. channel.icon .. '</span>'
   end
   self:set_markup(self.format:format(label, channel.control.volume))
end

-- Raise volume
function PulseAudioWidget:raise(value, channel_num)
   local channel = self:select_channel(channel_num)
   value = value or channel.step
   channel.control:raise(value)
   self:refresh()
end

-- Lower volume
function PulseAudioWidget:lower(value, channel_num)
   local channel = self:select_channel(channel_num)
   value = value or channel.step
   channel.control:lower(value)
   self:refresh()
end

-- Mute or unmute channel
function PulseAudioWidget:toggle(value, channel_num)
   local channel = self:select_channel(channel_num)
   channel.control:toggle()
   self:refresh()
end

-- Set selected channel
function PulseAudioWidget:select(channel_num)
   self.selected = self.channels[channel_num]
end

-- Get channels table for awful.menu
function PulseAudioWidget:get_menu_items()
   local channel_list = {}
   for k, v in pairs(self.channels) do
      channel_list[k] = { v.icon .. " " .. v.label,
                          function ()
                             self.selected = self.channels[k]
                             self:update()
      end }
   end
   return channel_list
end

-- Create widget
local function new(args)
   if not args.settings then args.settings = {} end

   -- Create widget
   settings = args.settings or {}
   local obj = wibox.widget.textbox()
   for k, v in pairs(PulseAudioWidget) do
      if type(v) == "function" then
         obj[k] = v
      end
   end

   if not args.channel_list then
      -- Set default channel from default sink
      local default = PulseChannel.get_default('sink')
      args.channel_list = {
         {icon = "♪", channel_type = 'sink', name = default, label = 'Default'}
      }
   end

   -- Set settings
   obj.channels = {}
   obj.format = args.settings.format or "%s% 3d%%"
   obj.color = {
      muted = args.settings.color_muted or "#F80000", -- Red
      unmuted = args.settings.color_unmuted or "#00EE00"  -- Green
   }
   obj.error_msg = args.settings.error_msg or '<span color="#FF0004">#</span>'
   obj.notify_errors = true
   if args.settings.notify_errors == false then
      obj.notify_errors = false
   end
   menu_theme = args.settings.menu_theme or { width = 120, height = 15 }
   obj.step = args.settings.step or 1
   -- Create channels list
   for k, v in pairs(args.channel_list) do
      obj.channels[k] = {
         icon = v.icon,
         label = v.label,
         name = v.name,
         control = PulseChannel:new(v.channel_type, v.name, v.max_volume or 100),
         step = v.step or obj.step,
         selected = false
      }
   end
   obj.selected = obj.channels[1]
   -- Run pactl once to start pulse if socket activation is used
   awful.spawn.easy_async('pactl info', function(out)
                             -- Pipewire actually has internal async
                             -- device load so completed pactl doesn't
                             -- mean that devices really here. Timeout
                             -- tries to solve possible single error
                             -- print on first load in that case.
                             timer.start_new(2, function () obj:update() end)
   end)

   -- Add menu
   local channel_menu
   if #obj.channels ~= 1 then
      channel_menu = awful.menu({ items = obj:get_menu_items(),
                                  theme = menu_theme })
   end

   -- Bind buttons if needed
   if not args.settings.dont_bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:toggle() end),
            awful.button({ }, 3, function ()
                  if channel_menu then
                     channel_menu:toggle()
                  end
            end),
            awful.button({ }, 4, function () obj:raise() end),
            awful.button({ }, 5, function () obj:lower() end),
            awful.button({ "Shift" }, 4, function () obj:raise(obj.step * 10) end),
            awful.button({ "Shift" }, 5, function () obj:lower(obj.step * 10) end),
            awful.button({ "Control" }, 4, function () obj:raise(obj.step * 5) end),
            awful.button({ "Control" }, 5, function () obj:lower(obj.step * 5) end)
      ))
   end

   -- Init update timer
   refresh_timer = timer({ timeout = args.settings.refresh_timeout or 10 })
   refresh_timer:connect_signal("timeout", function() obj:update() end)
   refresh_timer:start()
   return obj
end

function PulseAudioWidget.mt:__call(...)
   return new(...)
end

return setmetatable(PulseAudioWidget, PulseAudioWidget.mt)
