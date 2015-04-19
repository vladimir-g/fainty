=====================
 fainty.widgets.alsa 
=====================

ALSA widget displays current output channel volume and state
(muted/unmuted). Default key bindings allow to raise/lower volume with
scroll wheel and mute output with left click. Right click opens
dropdown menu with list of defined outputs, allowing to select and
control different output.

Usage
=====

Create widget somewhere in the top of your rc.lua, but after
beautiful.init::

  local alsawidget = fainty.widgets.alsa({
        card_list = {
           {label = "♪", cardid = 0,
            channel = "Master", name = "Speakers"},
           {label = "☊", cardid = 1, 
            channel = "Master", name = "Headphones"},
           {label = "⚫", cardid = 1, 
            channel = "Capture", name = "Microphone"}
        }
  })

Then add widget to layout like awful.widget.textbox::

  right_layout:add(alsawidget)

Multimedia keys could be binded to widget's methods::

  awful.key({ }, "XF86AudioRaiseVolume", function () alsawidget:raise(3) end),
  awful.key({ }, "XF86AudioLowerVolume", function () alsawidget:lower(3) end),
  awful.key({ }, "XF86AudioMute", function () alsawidget:toggle() end),


Customization
=============

Constructor looks like this::

  fainty.widgets.alsa({ card_list = {...}, settings = {...} )

Arguments:

* **card_list**

  Table of channels that shoud be managed by this widget. Example::

    { 
      {label = "♪", cardid = 0, channel = "Master", name = "Speakers"},
      -- ... other channels ...
    }

  Each channel is also a table that has these keys:

  + **label** - icon that will be used in widget for this channel
  + **cardid** - ALSA ID of card
  + **channel** - name of this channel ("Master", "Capture" etc)
  + **name** - name of this channel in dropdown menu

* **settings**

  Optional table with widget settings. Defaults used if none provided.

  Example of table with all settings and their default values::

    {
      color_muted = "#F80000",
      color_unmuted = "#00EE00",
      format = "%s% 3d%%",
      menu_theme = { width = 120, height = 15 },
      error_msg = '<span color="#FF0004">#</span>',
      notify_errors = true,
      dont_bind_buttons = false,
      refresh_timeout = 10
      step = 1
    }
  
  Description:
  
  + **color_muted** - color of label when channel is muted
  + **color_unmuted** - same for unmuted channel
  + **format** - format string for volume level in percents
  + **menu_theme** - theme parameters for dropdown menu
  + **error_msg** - widget text displayed on error
  + **notify_errors** - show naughty notification message on error
  + **dont_bind_buttons** -- don't bind buttons when widget is created
  + **refresh_timeout** - how frequently volume level would be
    synced.
  + **step** - default step for raise/lower volume action

Available widget methods (for currently selected channel):

* **AlsaWidget:raise(num)** - increase volume of selected card by num
* **AlsaWidget:lower(num)** - decrease volume of selected card by num
* **AlsaWidget:toggle()** - mute or unmute selected card

Other methods available in code.
