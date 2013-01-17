---------------------
-- Calendar widget --
---------------------
-- Copyright (c) 2012, 2013 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local awful = require("awful")
local wibox = require("wibox")
local setmetatable = setmetatable
local string = string
local tonumber = tonumber
local io = io
local os = os

local CalendarWidget = { mt = {} }

CalendarWidget.date = {}

-- Trim spaces from the right end
function CalendarWidget.rtrim(str)
   local n = #str
   while n > 0 and str:find("^%s", n) do n = n - 1 end
   return str:sub(1, n)
end

-- Show calendar for current month
function CalendarWidget:reset_date()
   self.date = { month = tonumber(os.date("%m")), 
                 year = tonumber(os.date("%Y")) }
   self:update()
end

-- Show calendar for next month
function CalendarWidget:next_month()
   local month = self.date.month + 1
   local year = self.date.year
   if month == 13 then
      month = 1
      year = year + 1
   end
   self.date.month = month
   self.date.year = year
   self:update()
end

-- Show calendar for previous month
function CalendarWidget:prev_month()
   local month = self.date.month - 1
   local year = self.date.year
   if month == 0 then
      month = 12
      year = year - 1
   end
   self.date.month = month
   self.date.year = year
   self:update()
end

-- Update tooltip with new calendar
function CalendarWidget:update()
   -- Run cal
   local cmd = string.format("cal %s %i %i", self.settings.opts,
                             self.date.month, self.date.year)
   local fd = io.popen(cmd)
   -- Check return code and get output
   if not fd then return end
   local result = fd:read("*all")
   local retcode = fd:close()
   if not retcode then return end
   result = self.rtrim(result)
   -- Highlight current day if needed
   if self.settings.highlight_day then
      local month, year = tonumber(os.date("%m")), tonumber(os.date("%Y"))
      if self.date.month == month and self.date.year == year then
         local day = os.date("%d")
         result = result:gsub(
            "([^%d])" .. day,
            "%1" .. string.format(self.settings.day_fmt, day))
      end
   end
   self.calendar:set_markup('<span font="monospace">' .. result .. '</span>')
end

-- Set geometry and position of calendar wibox
function CalendarWidget:place()
   -- Placement
   awful.placement.under_mouse(self.wibox)
   awful.placement.no_offscreen(self.wibox)
   -- Geometry
   local geom = self.wibox:geometry()
   local n_w, n_h = self.calendar:fit(-1, -1)
   if geom.width ~= n_w or geom.height ~= n_h then
      self.wibox:geometry({ width = n_w, height = n_h })
   end
end

-- Toggle calendar wibox visibility
function CalendarWidget:toggle()
   if self.wibox.visible == false then
      self:show()
   else
      self:hide()
   end
end

-- Show calendar wibox
function CalendarWidget:show()
   if self.wibox.visible then return end
   -- Reset calendar to current month on show
   if not self.settings.dont_reset_on_show then
      self:reset_date()
   end
   self:place()
   self.wibox.visible = true
end

-- Hide calendar wibox
function CalendarWidget:hide()
   if not self.wibox.visible then return end
   self.wibox.visible = false
end

-- Create new CalendarWidget instance
local function new(fmt, timeout, settings)
   local obj = awful.widget.textclock(fmt, timeout)
   for k, v in pairs(CalendarWidget) do
      obj[k] = v
   end
   obj.settings = settings or { opts = "", day_fmt = "<u>%s</u>", 
                                highlight_day = true }
   -- Create textbox with calendar
   obj.calendar = wibox.widget.textbox()
   -- Create wibox
   obj.wibox = wibox({})
   obj:hide()
   obj:reset_date()             -- Set initial date
   obj.wibox.ontop = true
   obj.wibox:set_widget(obj.calendar)
   obj:place()
   -- Bind buttons
   if not obj.settings.dont_bind_buttons then
      obj:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () obj:toggle() end),
            awful.button({ }, 2, function () obj:reset_date() end),
            awful.button({ }, 4, function () obj:next_month() end),
            awful.button({ }, 5, function () obj:prev_month() end)
                              ))
   end
   return obj
end

function CalendarWidget.mt:__call(...)
   return new(...)
end

return setmetatable(CalendarWidget, CalendarWidget.mt)
