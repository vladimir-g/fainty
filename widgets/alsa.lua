local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local setmetatable = setmetatable
local io = io
local pairs = pairs
local timer = timer
local type = type

-- Alsa controller class
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
   awful.util.spawn_with_shell("amixer -q -c " .. self.cardid .. 
                               " -- sset " .. self.channel
                               .. " " .. value .. "+", false)
end

-- Lower card volume
function AlsaChannel:lower(value)
   value = value or 1
   awful.util.spawn_with_shell("amixer -q -c " .. self.cardid .. 
                               " -- sset " .. self.channel
                               .. " " .. value .. "-", false)
end

-- Mute or unmute card
function AlsaChannel:toggle()
   awful.util.spawn("amixer -q -c " .. self.cardid .. 
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
      naughty.notify({ preset = naughty.config.presets.critical,
                       title = "Error in alsa widget",
                       text = "Error while trying to run amixer" })
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
   value = value or 1
   local card = self:select_card(card_num)
   card.control:raise(value)
   self:refresh()
end

-- Lower volume
function AlsaWidget:lower(value, card_num)
   value = value or 1
   local card = self:select_card(card_num)
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
-- Example:
-- require('lib.volume_widget')
-- volume_wgt = lib.volume_widget(card_list, settings}
-- Initialize widget only after beautiful.init (for dropdown menu).
-- Use colume_wgt.widget when adding widget to wibox.
--
-- Arguments:
--
-- card_list - table with cards
-- Keys: 
-- label - string displayed in widget
-- cardid - card ID
-- channel - channel
-- name - string for menu
-- Example: 
-- {{label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
--  {label = "☊", cardid = 1, channel = "Master", name = "Headphones"},
--  {label = "⚫", cardid = 1, channel = "Capture", name = "Microphone"}}
--
-- settings - table with widget settings (optional)
-- Keys:
-- color_muted - color for label in muted state
-- color_unmuted - color for label in unmuted state
-- refresh_timeout - update timeout
-- format - widget text format
-- Example (with default values): 
-- { color_muted = "#F80000", color_unmuted = "#00EE00",
--   refresh_timeout = 10, format = "%s% 3d%%" }
local function new(card_list, settings)
   if not card_list then
      return nil
   end
   -- Create widget
   settings = settings or {}
   local obj = wibox.widget.textbox()
   -- Put AlsaWidet's methods to textbox, some kind of multiple inheritance
   for k, v in pairs(AlsaWidget) do
      if type(v) == "function" then
         obj[k] = v
      end
   end
   -- Set settings
   obj.cards = {}
   obj.format = settings.format or "%s% 3d%%"
   obj.color = {
      muted = settings.color_muted or "#F80000", -- Red
      unmuted = settings.color_unmuted or "#00EE00"  -- Green
   }
   obj.error_msg = settings.error_msg or '<span color="#FF0004">#</span>'
   menu_theme = settings.menu_theme or { width = 120, height = 15 }
   -- Create card list
   for k, v in pairs(card_list) do
      obj.cards[k] = { 
         label = v.label,
         name = v.name or "",
         control = AlsaChannel:new(v.cardid, v.channel),
         selected = false
      }
   end
   obj.selected = obj.cards[1]
   obj:refresh()
   -- Add menu
   local card_menu = awful.menu({ items = obj:get_menu_items(),
                                  theme = menu_theme })
   -- Bind buttons
   obj:buttons(
      awful.util.table.join(
         awful.button({ }, 1, function () obj:toggle() end),
         awful.button({ }, 3, function () card_menu:toggle() end),
         awful.button({ }, 4, function () obj:raise() end),
         awful.button({ }, 5, function () obj:lower() end),
         awful.button({ "Shift" }, 4, function () obj:raise(10) end),
         awful.button({ "Shift" }, 5, function () obj:lower(10) end),
         awful.button({ "Control" }, 4, function () obj:raise(5) end),
         awful.button({ "Control" }, 5, function () obj:lower(5) end)
                           ))
   -- Set update timer
   refresh_timer = timer({ timeout = settings.refresh_timeout or 10 })
   refresh_timer:connect_signal("timeout", function() obj:refresh() end)
   refresh_timer:start()
   return obj
end

function AlsaWidget.mt:__call(...)
   return new(...)
end

return setmetatable(AlsaWidget, AlsaWidget.mt)
