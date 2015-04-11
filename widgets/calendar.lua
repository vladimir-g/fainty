---------------------
-- Calendar widget --
---------------------
-- Copyright (c) 2012-2015 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local awful = require("awful")
local wibox = require("wibox")
local setmetatable = setmetatable
local string = string
local tonumber = tonumber
local table = table
local io = io
local os = os

local CalendarWidget = { mt = {} }

CalendarWidget.date = {}

-- Show calendar for current month
function CalendarWidget:reset_date()
   local date = os.date("*t")
   self.date = { month = date.month,
                 year = date.year }
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

-- Create textbox with margin
function CalendarWidget:make_textbox(contents)
   local wgt_box = wibox.widget.textbox()
   wgt_box:set_markup(contents)
   wgt_box:set_align('right')
   local wgt = wibox.widget.base.make_widget(wgt_box)

   local layout = wibox.layout.margin()
   layout:set_widget(wgt)
   layout:set_margins(2)        -- FIXME

   local width, height = nil, nil
   -- Get widget size on first run
   if not self.max_box_width or not self.max_box_height then
      width, height = wgt:fit(-1, -1)
   end

   return layout, width, height
end

-- Update tooltip with new calendar
function CalendarWidget:update()

   self.calendar:reset()

   -- Dates
   local current_day = os.date('*t')
   local month_start = os.date('*t', os.time{year=self.date.year,
                                             month=self.date.month, day=1})
   local month_end = os.date('*t', os.time{year=self.date.year,
                                           month=self.date.month+1, day=0})
   local prev_month_end_day = tonumber(
      os.date('%d', os.time{year=self.date.year,
                            month=self.date.month, day=0})
   )

   -- Current month
   -- self.monthtable[self.date.month])
   local month_wgt = wibox.widget.textbox()
   month_wgt:set_markup('<b>' .. self.monthtable[self.date.month] ..
                           ' ' .. self.date.year .. '</b>')
   month_wgt:set_align('center')
   self.calendar:add(month_wgt)

   week_start = self.settings.week_start

   local widths, heights, boxes = {}, {}, {}

   -- Add box to row and save width and height
   local function insert_box(row, box, width, height)
      if not self.max_box_width then
         table.insert(widths, width)
      end
      if not self.max_box_height then
         table.insert(heights, height)
      end
      table.insert(boxes, box)
      row:add(box)
   end

   local row = wibox.layout.fixed.horizontal()
   for i=0,6 do
      box, w, h = self:make_textbox(self.daytable[(i + week_start) % 7 + 1])
      insert_box(row, box, w, h)
   end
   self.calendar:add(row)

   local count = 0
   local first_offset = (month_start.wday - week_start - 1) % 7
   row = wibox.layout.fixed.horizontal()
   -- Previous month days
   for i=1,first_offset do
      local day = prev_month_end_day - (first_offset - i)
      if self.settings.show_other_month then
         label = '<span foreground="' ..
            self.settings.other_month_color .. '">' ..
            day .. '</span>'
      else
         label = ''
      end
      box, w, h = self:make_textbox(label)
      insert_box(row, box, w, h)
      count = count + 1
   end

   -- row = wibox.layout.fixed.horizontal()
   for i=1,month_end.day do
      local label = i
      if (i == current_day.day and self.date.month == current_day.month) then
         label = self.settings.day_fmt:format(label)
      end

      box, w, h = self:make_textbox(label)
      insert_box(row, box, w, h)

      count = count + 1
      if count % 7 == 0 then
         self.calendar:add(row)
         row = wibox.layout.fixed.horizontal()
      end
   end
   local remain = 7 - count % 7

   if remain ~= 0 and remain ~= 7 then
      for i=1,remain do
         if self.settings.show_other_month then
            label = '<span foreground="' ..
               self.settings.other_month_color .. '">' ..
               i .. '</span>'
         else
            label = ''
         end
         box, w, h = self:make_textbox(label)
         insert_box(row, box, w, h)
      end
      self.calendar:add(row)
   end

   self:set_box_sizes(boxes, widths, heights)
end

-- Set calendar cell sizes to maximum size of cell
function CalendarWidget:set_box_sizes(boxes, widths, heights)
   local max_width = self.max_box_width
   if not max_width then
      table.sort(widths)        -- Not so optimal sorting method, FIXME
      max_width = widths[#widths]
      self.max_box_width = max_width
   end

   local max_height = self.max_box_height
   if not max_height then
      table.sort(heights)
      max_height = heights[#heights]
      self.max_box_height = max_height
   end

   for i, box in ipairs(boxes) do
      box.widget.fit = function (_, w, h)
         return max_width, max_height
      end
   end
end

-- Set geometry and position of calendar wibox
function CalendarWidget:place()
   -- Placement
   awful.placement.under_mouse(self.wibox)
   awful.placement.no_offscreen(self.wibox)
   -- Geometry
   local geom = self.wibox:geometry()
   local n_w, n_h = self.calendar:fit(9999, 9999) -- An hack
   -- if geom.width ~= n_w or geom.height ~= n_h then
      self.wibox:geometry({ width = n_w, height = n_h })
   -- end
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

function CalendarWidget:init_names()
   -- Set locale
   local old_locale = os.setlocale()
   if self.settings.locale then
      os.setlocale(self.settings.locale)
   end

   self.daytable = {}
   for i=19,25 do
      table.insert(self.daytable,
                   os.date('%a', os.time{year=1986, month=1, day=i}))
   end

   self.monthtable = {}
   for i=1,12 do
      table.insert(self.monthtable,
                   os.date('%B', os.time{year=1986, month=i, day=1}))
   end

   -- Reset locale
   if self.settings.locale then
      os.setlocale(old_locale)
   end
end

-- Create new CalendarWidget instance
local function new(args)
   local obj = awful.widget.textclock(args.fmt, args.timeout)
   for k, v in pairs(CalendarWidget) do
      obj[k] = v
   end

   -- Set settings
   obj.settings = {
      week_start = args.settings.week_start or 1,
      day_fmt = args.settings.day_fmt or "<u><b>%s</b></u>",
      locale = args.settings.locale,
      other_month_color = args.settings.other_month_color or 'gray',
      show_other_month = args.settings.show_other_month or true
   }
   -- Get locale-specific month and day names
   obj:init_names()
   -- Internal layout
   obj.calendar = wibox.layout.fixed.vertical()
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
