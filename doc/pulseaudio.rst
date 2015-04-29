===========================
 fainty.widgets.pulseaudio
===========================

PulseAudio widget displays volume and state (muted/unmuted) for sink
or source (called *channel* in code). Default key bindings allow to
raise/lower volume with scroll wheel and mute output with left
click. Right click opens dropdown menu with list of defined outputs,
allowing to select and control different channel.

Requires **pacmd**, **pactl** and pulseaudio server of course. Consult
PulseAudio documentation for more about sinks and sources.

Usage
=====

Create widget somewhere in the top of your rc.lua, but after
beautiful.init::

  pulsewidget = fainty.widgets.pulseaudio({
      channel_list = {
         { icon = "♪", channel_type = 'sink', label = "Speakers",
           name = "alsa_output.pci-0000_04_07.0.analog-stereo" },
         { icon = "☊", channel_type = 'sink', label = "Headphones",
           name = "alsa_output.pci-0000_00_14.2.analog-stereo" },
         { icon = "⚫", channel_type = 'source', label = 'Microphone', 
           name = "alsa_input.pci-0000_00_14.2.analog-stereo"}
      }
  })

Then add widget to layout like awful.widget.textbox::

  right_layout:add(pulsewidget)

Multimedia keys could be binded to widget's methods::

  awful.key({ }, "XF86AudioRaiseVolume", function () pulsewidget:raise(3) end),
  awful.key({ }, "XF86AudioLowerVolume", function () pulsewidget:lower(3) end),
  awful.key({ }, "XF86AudioMute", function () pulsewidget:toggle() end),


Customization
=============

Constructor looks like this::

  fainty.widgets.pulseaudio({ channel_list = {...}, settings = {...} )

Arguments:

* **channel_list**

  Optional table of channels that shoud be managed by this
  widget. If not provided, default sink will be used.

  Example::

    { 
      { icon = "♪", channel_type = 'sink', label = "Speakers",
        name = "alsa_output.pci-0000_04_07.0.analog-stereo",
        max_volume = 100 },
      -- ... other channels ...
    }

  Each channel is also a table that has these keys:

  + **icon** - symbol that will be used in widget for this channel.
  + **channel_type** - 'sink' or 'source'.
  + **name** - internal PulseAudio name (obtained with pacmd).
  + **label** - name for popup menu.
  + **max_volume** - maximum volume value in percents (default: 100).

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
  + **step** - default step for raise/lower volume action (percents)

Available widget methods (for currently selected channel):

* **PulseAudioWidget:raise(num)** - increase volume of selected channel by num
* **PulseAudioWidget:lower(num)** - decrease volume of selected channel by num
* **PulseAudioWidget:toggle()** - mute or unmute selected channel

Other methods available, look in code.
