-----------------------
-- ALSA volume widget--
-----------------------
-- Copyright (c) 2012-2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local setmetatable = setmetatable
local io = io
local pairs = pairs
local timer = require("gears.timer")
local type = type

-- Channel object, represents one channel of sound device
local AlsaChannel = {}

function AlsaChannel:new(cardid, channel)
   local new_instance = { cardid = cardid, channel = channel }
   setmetatable(new_instance, { __index = AlsaChannel })
   return new_instance
end

-- Get card volume and muted state
function AlsaChannel:get_data()
   local data = {}
   local fd = io.popen("amixer -c " .. self.cardid ..
                       " -- sget " .. self.channel)
   if not fd then return end
   local result = fd:read("*all")
   local retcode = fd:close()
   if not retcode then       -- Invalid card or other error
      return
   end
   -- Get volume
   data.volume = result:match("(%d+)%%")
   if not data.volume then
      data.volume = ""
   end
   -- Get status
   local status = result:match("%[(o[^%]]*)%]")
   if not status then status = "on" end
   if status:find("on", 1, true) then
      data.mute = false
   else
      data.mute = true
   end
   return data
end

-- Raise card volume
function AlsaChannel:raise(value)
   value = value or 1
   awful.spawn_with_shell("amixer -q -c " .. self.cardid ..
                             " -- sset " .. self.channel
                             .. " " .. value .. "+", false)
end

-- Lower card volume
function AlsaChannel:lower(value)
   value = value or 1
   awful.spawn_with_shell("amixer -q -c " .. self.cardid ..
                             " -- sset " .. self.channel
                             .. " " .. value .. "-", false)
end

-- Mute or unmute card
function AlsaChannel:toggle()
   awful.spawn("amixer -q -c " .. self.cardid ..
                    " sset " .. self.channel .. " toggle", false)
end

-- Widget class
local AlsaWidget = { mt = {} }

-- Set selected card
-- card_num - card position in initially provided card array
function AlsaWidget:select_card(card_num)
   if not card_num then
      return self.selected
   else
      return self.cards[card_num]
   end
end

-- Refresh card state
function AlsaWidget:refresh(card_num)
   local card = self:select_card(card_num)
   local data = card.control:get_data()
   local label = ''
   if not data then
      self:set_markup(self.error_msg)
      if self.notify_errors then
         naughty.notify({ preset = naughty.config.presets.critical,
                          title = "Error in alsa widget",
                          text = "Error while trying to run amixer" })
      end
      return
   end
   if data.mute then
      label = '<span color="' .. self.color.muted .. '">'
         .. card.label .. '</span>'
   else
      label = '<span color="' .. self.color.unmuted .. '">'
         .. card.label .. '</span>'
   end
   self:set_markup(self.format:format(label, data.volume))
end

-- Raise volume
function AlsaWidget:raise(value, card_num)
   local card = self:select_card(card_num)
   value = value or card.step
   card.control:raise(value)
   self:refresh()
end

-- Lower volume
function AlsaWidget:lower(value, card_num)
   local card = self:select_card(card_num)
   value = value or card.step
   card.control:lower(value)
   self:refresh()
end

-- Mute or unmute card
function AlsaWidget:toggle(value, card_num)
   value = value or 1
   local card = self:select_card(card_num)
   card.control:toggle()
   self:refresh()
end

-- Set selected card
function AlsaWidget:select(card_num)
   self.selected = self.cards[card_num]
end

-- Get cards table for awful.menu
function AlsaWidget:get_menu_items()
   local card_list = {}
   for k, v in pairs(self.cards) do
      card_list[k] = { v.label .. " " .. v.name,
                       function ()
                          self.selected = self.cards[k]
                          self:refresh()
                       end }
   end
   return card_list
end

-- Create widget
local function new(args)
   if not args.settings then args.settings = {} end

   if not args.card_list then
      -- Set default card
      args.card_list = {
         {label = "♪", cardid = 0, channel = "Master", name = "Default"}
      }
   end

   -- Create widget
   settings = args.settings or {}
   local obj = wibox.widget.textbox()

   for k, v in pairs(AlsaWidget) do
      if type(v) == "function" then
         obj[k] = v
      end
   end

   -- Set settings
   obj.cards = {}
   obj.format = args.settings.format or "%s% 3d%%"
   obj.color = {
      muted = args.settings.color_muted or "#F80000", -- Red
      unmuted = args.settings.color_unmuted or "#00EE00"  -- Green
   }
   obj.error_msg = args.settings.error_msg or '<span color="#FF0004">#</span>'
   obj.notify_errors = args.settings.notify_errors or true
   menu_theme = args.settings.menu_theme or { width = 120, height = 15 }
   obj.step = args.settings.step or 1
   -- Create card list
   for k, v in pairs(args.card_list) do
      obj.cards[k] = {
         label = v.label,
         name = v.name or "",
         control = AlsaChannel:new(v.cardid, v.channel),
         step = v.step or obj.step,
         selected = false
      }
   end
   obj.selected = obj.cards[1]
   obj:refresh()

   -- Add menu
   local card_menu = awful.menu({ items = obj:get_menu_items(),
                                  theme = menu_theme })

   -- Bind buttons if needed
   if not args.settings.dont_bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:toggle() end),
            awful.button({ }, 3, function () card_menu:toggle() end),
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

function AlsaWidget.mt:__call(...)
   return new(...)
end

return setmetatable(AlsaWidget, AlsaWidget.mt)
