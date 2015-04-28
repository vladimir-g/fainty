-----------------------------
-- PulseAudio volume widget--
-----------------------------
-- Copyright (c) 2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local setmetatable = setmetatable
local io = io
local pairs = pairs
local timer = timer
local type = type

-- Object that represents sink or source
local PulseChannel = {}

-- Crate new channel, accepts type and name or index
function PulseChannel:new(channel_type, name, max_volume)
   local new_instance = {
      channel_type = channel_type,
      name = name,
      max_volume = max_volume
   }
   setmetatable(new_instance, { __index = PulseChannel })
   return new_instance
end

-- Get channel volume and muted state
function PulseChannel:get_data()
   -- TODO maybe move to separate object

   -- Read data
   local fd = io.popen('pacmd list-' .. self.channel_type .. 's')
   if not fd then return end
   local result = fd:read("*all")
   local retcode = fd:close()

   if not retcode then       -- Invalid channel or other error
      return
   end

   -- Parse data
   local data = {}
   local current_index = nil
   for line in result:gmatch("[^\n]+") do
      -- Index
      line:gsub('index: (%d)', function (index)
                   current_index = tonumber(index)
                   data[current_index] = { index = index }
      end)

      -- Volume
      line:gsub('^%s+volume:[^/]+/%s+(%d+)%%', function (volume)
                   data[current_index].volume = tonumber(volume)
      end)

      -- Name
      line:gsub('^%s+name:%s+<([^>]+)', function (name)
                   data[current_index].name = name
      end)

      -- Muted status
      line:gsub('muted:%s+(%w+)', function (status)
                   if status == 'no' then
                      data[current_index].muted = false
                   else
                      data[current_index].muted = true
                   end
      end)

   end

   -- Find channel
   items = {}
   for k, v in pairs(data) do
      if v.name == self.name then
         return v
      end
   end

end

-- Get dafault sink or source data
function PulseChannel.get_default(channel_type)
   local fd = io.popen('pacmd list-' .. channel_type .. 's')
   if not fd then return end
   local result = fd:read("*all")
   local retcode = fd:close()

   if not retcode then
      return
   end

   -- Parse data
   local data = {}
   local in_default = false;
   for line in result:gmatch("[^\n]+") do
      -- Index
      line:gsub('* index: (%d)', function (index)
                   in_default = true
                   data.index = index
      end)

      -- Volume
      line:gsub('^%s+volume:[^/]+/%s+(%d+)%%', function (volume)
                   if in_default then
                      data.volume = tonumber(volume)
                   end
      end)

      -- Name
      line:gsub('^%s+name:%s+<([^>]+)', function (name)
                   if in_default then
                      data.name = name
                   end
      end)
   end
   return data
end

-- Raise channel volume
function PulseChannel:raise(value)
   value = value or 1
   local status = self:get_data()
   if status.volume + value > self.max_volume then
      value = self.max_volume - status.volume
   end
   awful.util.spawn("pactl set-" .. self.channel_type .. "-volume " ..
                       self.name .. ' +' .. value .. '%')
end

-- Lower channel volume
function PulseChannel:lower(value)
   value = value or 1
   local status = self:get_data()
   if status.volume - value < 0 then
      value = status.volume
   end
   awful.util.spawn("pactl set-" .. self.channel_type .. "-volume " ..
                       self.name .. ' -' .. value .. '%')
end

-- Mute or unmute channel
function PulseChannel:toggle()
   awful.util.spawn("pactl set-" .. self.channel_type .. "-mute " ..
                       self.name .. " toggle")
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
function PulseAudioWidget:refresh(channel_num)
   local channel = self:select_channel(channel_num)
   local data = channel.control:get_data()
   local label = ''
   if not data then
      self:set_markup(self.error_msg)
      if self.notify_errors then
         naughty.notify({ preset = naughty.config.presets.critical,
                          title = "Error in pulseaudio widget",
                          text = "Error while trying to run pacmd" })
      end
      return
   end
   if data.muted then
      label = '<span color="' .. self.color.muted .. '">'
         .. channel.icon .. '</span>'
   else
      label = '<span color="' .. self.color.unmuted .. '">'
         .. channel.icon .. '</span>'
   end
   self:set_markup(self.format:format(label, data.volume))
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
                          self:refresh()
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
         {icon = "♪", channel_type = 'sink', name = default.name, label = 'Default'}
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
   obj.notify_errors = args.settings.notify_errors or true
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
   obj:refresh()

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
   refresh_timer:connect_signal("timeout", function() obj:refresh() end)
   refresh_timer:start()
   return obj
end

function PulseAudioWidget.mt:__call(...)
   return new(...)
end

return setmetatable(PulseAudioWidget, PulseAudioWidget.mt)
