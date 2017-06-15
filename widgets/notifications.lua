--------------------------
-- Notifications widget --
--------------------------
-- Copyright (c) 2016 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local wibox = require("wibox")
local awful = require('awful')
local utils = require("fainty.utils")
local base = require("fainty.widgets.base")
local naughty = require("naughty")
local timer = require("gears.timer")
local setmetatable = setmetatable
local os = os
local pairs = pairs
local table = table

-- Widget class
local NotificationsWidget = { mt = {} }

-- Add notification to inner list
function NotificationsWidget:notify(args)
   if args.timeout then
      args.expired_time = os.time() + args.timeout
   else
      args.expired_time = nil
   end
   table.insert(self.notifications, args)

   -- Add callback that will remove notification on click
   local old_run = args.run
   local id = #self.notifications
   args.run = function (n)
      if id <= #self.notifications then
         table.remove(self.notifications, id)
      end
      if old_run then
         old_run(n)
      end
      n.die()
      self:refresh()
   end
   self:refresh()
   return args
end

-- Clear notifications list
function NotificationsWidget:clear()
   self.notifications = {}      -- Maybe just clear it?
   self:refresh()
   self:hide_popup()
end

-- Redraw widget
function NotificationsWidget:refresh()
   local count = #self.notifications

   -- Get count of expired popups
   local current_time = os.time()
   local expired = 0
   for k, v in pairs(self.notifications) do
      if v.expired_time and v.expired_time < current_time then
         expired = expired + 1
         v.expired = true
      end
   end

   local values = {
      count = count,
      expired = expired,
      active = count - expired
   }

   -- Update popup with list of messages
   if self.settings.show_popup then
      local text = ''
      for k, v in pairs(self.notifications) do
         if self.settings.show_expired or not v.expired then
            if v.title then
               text = text .. "<b>" .. v.title .. "</b>: "
            end
            text = text .. v.text .. "\n"
         end
      end
      self.popup_wgt:set_markup(text)
   end

   -- Update markup
   if naughty.is_suspended() then
      self:set_markup(self.settings.suspended_tpl % values)
   elseif self.settings.active_callback(self) then
      self:set_markup(self.settings.active_tpl % values)
   else
      self:set_markup(self.settings.empty_tpl % values)
   end
end

-- Don't toggle popup when there is no notifications
function NotificationsWidget:on_popup_show()
   active = 0
   expired = 0
   for _, v in pairs(self.notifications) do
      if v.expired then
         if self.settings.show_expired then
            expired = expired + 1
         end
      else
         active = active + 1
      end
   end
   return (active + expired) > 0
end

-- Create widget
local function new(args)
   settings = utils.merge_settings(
      args.settings or {},
      {
         active_tpl = ' <span color="#F80000"><b>[%(count)s]</b></span> ',
         suspended_tpl = ' <span color="#7D79A9"><b>[%(count)s]</b></span> ',
         empty_tpl = ' <span><b>[%(count)s]</b></span> ',
         show_popup = true,
         show_expired = true,
         active_callback = function (obj)
            return #obj.notifications ~= 0
         end,
         bind_buttons = true,
         refresh_timeout = 10
      }
   )
   local obj = base(wibox.widget.textbox())
   obj.settings = settings
   -- Put KbddWidget's methods to textbox
   for k, v in pairs(NotificationsWidget) do
      obj[k] = v
   end
   -- Popup
   if obj.settings.show_popup then
      obj:create_popup()
   end
   obj.notifications = {}
   naughty.config.notify_callback = function (args) return obj:notify(args) end
   obj:refresh()

   refresh_timer = timer({ timeout = settings.refresh_timeout })
   refresh_timer:connect_signal("timeout", function() obj:refresh() end)
   refresh_timer:start()

   -- Bind buttons
   if settings.bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:toggle_popup() end),
            awful.button({ }, 2, function ()
                  naughty.toggle()
                  obj:refresh()
            end),
            awful.button({ }, 3, function () obj:clear() end)
      ))
      obj.popup:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:hide_popup() end)
      ))
   end
   return obj
end

function NotificationsWidget.mt:__call(...)
   return new(...)
end

return setmetatable(NotificationsWidget, NotificationsWidget.mt)

