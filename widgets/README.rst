=========================
 Usage of fainty.widgets
=========================

This file contains full (maybe) documentation of fainty.widgets. Look
in source code for default key bindings.


fainty.widgets.alsa
===================

Create widget somewhere in the top of your rc.lua, but after
beautiful.init::

 local alsawidget = fainty.widgets.alsa({
   {label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
   {label = "☊", cardid = 1, channel = "Master", name = "Headphones"},
   {label = "⚫", cardid = 1, channel = "Capture", name = "Microphone"}})

Then add widget to layout like awful.widget.textbox::

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

* **card_list**

  Table of channels that shoud be controllable by this widget. Example::

    { 
      {label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
      -- ... other channels ...
    }

  Each channel is also a table. Keys:

  + **label** - icon that will be used in widget for this channel
  + **cardid** - ALSA ID of card
  + **channel** - name of this channel
  + **name** - name of this channel in dropdown menu

* **settings**

  Table of settings, optional. Defaults used if none provided.

  Example of table with all settings and their default values::

    { color_muted = "#F80000", color_unmuted = "#00EE00",
      format = "%s% 3d%%", error_msg = '<span color="#FF0004">#</span>',
      menu_theme = { width = 120, height = 15 }, dont_bind_buttons = false,
      refresh_timeout = 10 }
  
  Description:
  
  + **color_muted** - color of label when channel is muted
  + **color_unmuted** - same for unmuted channel
  + **format** - format string for volume level in percents
  + **error_msg** - widget text displayed on error
  + **menu_theme** - theme parameters for dropdown menu
  + **dont_bind_buttons** -- don't bind buttons when widget is created
  + **refresh_timeout** - how frequently volume level would be
    synced. Set it to small value if you use some other
    volume-controlling software.

Available widget methods. Them work on channel that currently
displayed in widget:

* **AlsaWidget:raise(num)** - increase volume of selected card by num
* **AlsaWidget:lower(num)** - decrease volume of selected card by num
* **AlsaWidget:toggle()** - mute or unmute selected card

You can use other methods too, look in code for more information.

fainty.widgets.kbdd
===================

Create widget somewhere in the top of your rc.lua, but after
beautiful.init (for proper dropdown menu styling)::

  local kbddwidget = fainty.widgets.kbdd({
      {label = "[En]", index = 0, name = "English"},
      {label = "[Ru]", index = 1, name = "Russian"} 
  })

Usage of all system layouts in the layout table isn't required.  Only
supplied layouts will be used in widget's methods like **next_layout** or
**prev_layout**. An example: if you have layouts *0*, *1* and *2*, and
you initialize the widget only with layouts *0* and *2*, method
**next_layout** will skip through *1*.

Then add widget to layout like standard awful.widget.textbox::

  right_layout:add(kbddwidget)

Customizing kbdd widget
-----------------------

Widget's contstructor::

  fainty.widgets.kbdd(layout_list, settings)

Arguments:

* **layout_list**

  Table of layouts available to widget. Example::
  
    {
      {label = "[En]", index = 0, name = "English", image="/path/to/img.png"},
      -- ... other layouts ...
    }

  Keys:
    
  + **label** -- text that will used for layout on widget
  + **index** -- layout's index (position in setxkbmap)
  + **name** -- name used in dropdown menu
  + **image** -- (optional) path to image that will be used in
    dropdown menu (not on widget itself)
  

* **settings**

  Table of settings, optional. All elements of this table are optional
  too. Defaults will be used if none provided.

  Example of table with all settings and their default values::

    { menu_theme = { width = 80, height = 15 }, dont_bind_buttons = false,
      error_msg = '<span color="#FF0004">[#]</span>' }

  Description:
  
  + **menu_theme** -- theme parameters for dropdown menu
  + **dont_bind_buttons** -- don't bind buttons when widget is created
  + **error_msg** -- text displayed on widget on error

fainty.widgets.calendar
=======================

Create widget somewhere in your rc.lua. Widget is based on
awful.widget.textclock, and you must provide textclock arguments to it::

 local calendar = fainty.widgets.calendar(" %a %d %b <b>%H:%M:%S</b> ", 1)

Add widget to layout like awful.widget.textclock::

  right_layout:add(calendar)

Customizing calendar widget
---------------------------

Constructor looks like this::

  fainty.widgets.calendar(fmt, timeout, settings)

First two arguments are passed to underlying textclock widget. Look
for their description in awesome documentation.

Arguments:

* **fmt**

  Textclock format.

* **timeout**

  Textclock timeout.

* **settings**

  Table of settings, optional. Defaults used if none provided.

  Example of table with all settings and their default values::

    { opts = "", day_fmt = "<u>%s</u>", highlight_day = true,
      dont_bind_buttons = false, dont_reset_on_show = false }
  
  Description:
  
  + **opts** - command line arguments for *cal* command. Look to *man cal*.
  + **day_fmt** - how current day must be formatted when
    highlighted. Must contain *%s* substring. Not needed when
    **highlight_day** is false.
  + **highlight_day** - highlight current day or not. Doesn't really
    work when argument "-3" is provided to cal command.
  + **dont_bind_buttons** -- don't bind buttons when widget is created
  + **dont_reset_on_show** - don't reset calendar to current month
    when calendar pops up.

Look to code for more information about widget's methods.
