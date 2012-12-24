=========================
 Usage of fainty.widgets
=========================

This file contains (maybe) full documentation of fainty.widgets.


fainty.widgets.alsa
===================

Create widget somewhere in the top of your rc.lua, but after
beautiful.init::

 local alsawidget = fainty.widgets.alsa({
   {label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
   {label = "☊", cardid = 1, channel = "Master", name = "Headphones"},
   {label = "⚫", cardid = 1, channel = "Capture", name = "Microphone"}})

Then add widget to layout like awesome.widget.textbox::

  right_layout:add(alsawidget)

If you have multimedia keys, bind them to widget's methods like this::

  awful.key({ }, "XF86AudioRaiseVolume", function () alsawidget:raise(3) end),
  awful.key({ }, "XF86AudioLowerVolume", function () alsawidget:lower(3) end),
  awful.key({ }, "XF86AudioMute", function () alsawidget:toggle() end),

That's all.

Customizing alsa widget
-----------------------

Constructor looks like this::

  fainty.widgets.alsa(card_list, settings)

Arguments:

* card_list

  Table of channels that shoud be controllable by this widget. Example::

    { 
      {label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
      -- ... other channels ...
    }

  Each channel is also a table. Keys:

  + label - icon that will be used in widget for this channel
  + cardid - ALSA ID of card
  + channel - name of this channel
  + name - name of this channel in dropdown menu

* settings

  Table of settings. Defaults used if none provided.

  Example of table with all settings and their default values::

    { color_muted = "#F80000", color_unmuted = "#00EE00",
      format = "%s% 3d%%", error_msg = '<span color="#FF0004">#</span>',
      menu_theme = { width = 120, height = 15 } }
  
  Description:
  
  + color_muted - color of label when channel is muted
  + color_unmuted - same for unmuted channel
  + format - format string for volume level in percents
  + error_msg - widget text displayed on error
  + menu_theme - theme parameters for dropdown menu

Available widget methods. Them work on channel that currently
displayed in widget:

* AlsaWidget:raise(num) - increase volume of selected card by num
* AlsaWidget:lower(num) - decrease volume of selected card by num
* AlsaWidget:toggle() - mute or unmute selected card

