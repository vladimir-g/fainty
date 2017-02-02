-----------------
-- Base widget --
-----------------
-- Copyright (c) 2016 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local wibox = require("wibox")
local awful = require('awful')
local capi = { screen = screen, mouse = mouse }
local pairs = pairs

local BaseWidget = {
   popup_margin = 5,
   show_popup = false,
   mt = {}
}

-- Default popup widget contents
function BaseWidget:get_popup_widget()
   return wibox.widget.textbox()
end

-- Default callbacks
function BaseWidget:on_popup_create() return end
function BaseWidget:on_popup_place() return end
function BaseWidget:on_popup_show() return end
function BaseWidget:on_popup_hide() return end
function BaseWidget:on_popup_toggle() return end

-- Create popup wibox
function BaseWidget:create_popup()
   if not self.show_popup then return end
   self:on_popup_create()
   self.popup = wibox({})
   self.popup.ontop = true
   local wgt = self:get_popup_widget()
   local container = wibox.container.margin()
   container:set_widget(wgt)
   container:set_margins(self.popup_margin)
   self.popup:set_widget(container)
   self.popup_layout = container
   self.popup_wgt = wgt
end

-- Set geometry and position of popup
function BaseWidget:place_popup()
   if not self.show_popup then return end
   self:on_popup_place()
   -- Placement
   awful.placement.under_mouse(self.popup)
   awful.placement.no_offscreen(self.popup)

   -- Geometry
   local geom = self.popup:geometry()
   local width = geom.width
   local height = geom.height
   local n_w, n_h = self.popup_wgt:get_preferred_size()
   n_w = n_w + self.popup_margin * 2
   n_h = n_h + self.popup_margin * 2

   local wa = capi.screen[capi.mouse.screen].workarea
   if width ~= n_w then
      width = n_w
   end
   if width > wa.width then
      width = wa.width - 20
   end

   if height ~= n_h then
      height = n_h
   end
   if height > wa.height then
      height = wa.height - 20
   end

   if width ~= geom.width or height ~= geom.height then
      if width ~= 0 and height ~= 0 then
         self.popup:geometry({ width = width, height = height })
      end
   end
end

-- Toggle info popup wibox visibility
function BaseWidget:toggle_popup()
   if not self.show_popup then return end
   self:on_popup_toggle()
   if self.popup.visible == false then
      self:show_popup()
   else
      self:hide_popup()
   end
end

-- Show popup
function BaseWidget:show_popup()
   if not self.show_popup then return end
   if self.popup.visible then return end
   self:place_popup()
   self:on_popup_show()
   self.popup.visible = true
end

-- Hide popup
function BaseWidget:hide_popup()
   if not self.show_popup then return end
   if not self.popup.visible then return end
   self:on_popup_hide()
   self.popup.visible = false
end

-- Create new base widget
local function new(widget)
   local obj = widget
   for k, v in pairs(BaseWidget) do
      obj[k] = v
   end
   return obj
end

function BaseWidget.mt:__call(...)
   return new(...)
end

return setmetatable(BaseWidget, BaseWidget.mt)
