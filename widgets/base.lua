-----------------
-- Base widget --
-----------------
-- Copyright (c) 2016 Vladimir Gorbunov
-- Release under MIT license, see LICENSE file for more details

local wibox = require("wibox")
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
   if not self.show_popup return end
   self:on_popup_create()
   self.popup = wibox({})
   self.popup.ontop = true
   local wgt = self:get_popup_widget()
   local layout = wibox.layout.margin()
   layout:set_widget(wgt)
   layout:set_margins(self.popup_margin)
   self.popup:set_widget(layout)
   self.popup_layout = layout
   self.popup_box = wgt
end

-- Set geometry and position of popup
function BaseWidget:place_popup()
   if not self.show_popup return end
   self:on_popup_place()
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
function BaseWidget:toggle_popup()
   if not self.show_popup return end
   self:on_popup_toggle()
   if self.popup.visible == false then
      self:show_popup()
   else
      self:hide_popup()
   end
end

-- Show popup
function BaseWidget:show_popup()
   if not self.show_popup return end
   if self.popup.visible then return end
   self:on_popup_show()
   self:place_popup()
   self.popup.visible = true
end

-- Hide popup
function BaseWidget:hide_popup()
   if not self.show_popup return end
   if not self.popup.visible then return end
   self:on_popup_hide()
   self.popup.visible = false
end

-- Create new base widget
local function new(widget)
   local wgt = widget
   for k, v in pairs(BaseWidget) do
      obj[k] = v
   end
   return wgt
end

function BaseWidget.mt:__call(...)
   return new(...)
end

return setmetatable(BaseWidget, BaseWidget.mt)
