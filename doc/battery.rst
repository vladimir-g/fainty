========================
 fainty.widgets.battery 
========================

Battery widget display battery information (remaining time etc) and
shows notifications when battery is low. Left click opens popup with
more information about battery. Left click on popup closes it.

Widget supports multiple batteries, but this is not really tested.

Python-like string interpolation is used for widget display format
options.

Usage
=====

Create widget somewhere in the top of your rc.lua::

  battery = fainty.widgets.battery({
      selected = "BAT0"
  })

Then add widget to layout like awful.widget.textbox::

  right_layout:add(battery)


Customization
=============

Constructor::

  fainty.widgets.battery({ selected = "...", settings = {...} })


Arguments:

* **selected**

  Optional selected battery name ("BAT0", "BAT1"). Names not starting
  with "BAT" currently ignored (will be fixed someday).

* **settings**

  Optional table with widget settings. Defaults::

   {
      fmt_discharging = ' <span color="#F80000">↯</span>%(percent)3d% (%(hours)d:%(minutes)02d)', -- Red color
      fmt_charging = ' <span color="#00EE00">↯</span>%(percent)3d% (%(hours)d:%(minutes)02d)', -- Green color
      fmt_unknown = ' <span color="#FFFFFF">↯</span>%(percent)3d%', -- White color
      fmt_warning = ' <span color="#F80000">↯!%(percent)3d%</span>', -- Full red
      fmt_not_present = ' <span color="#FFFFFF">↯</span> N/A', -- White color
      popup_fmt = 'Name: %(name)s\n' ..
         'Status: %(status)s\n' ..
         'Remaining: %(percent)s%\n' ..
         'Time: %(hours)s:%(minutes)s',
      show_popup = args.settings.show_popup or true,
      menu_theme = { width = 120, height = 15 },
      bind_buttons = true,
      warning_seconds = 600,
      refresh_timeout = 25,
      notify_warning = true,
      notify_warning_title = 'Low battery',
      notify_warning_text = 'Less than 10 minutes remaining'
   }

  Python-like string interpolation used for string formatting here,
  look to Python docs for more info. Next parameters are available for
  all formatting strings:

  + **name** - battery name.
  + **status** - battery status.
  + **percent** - battery capacity in percents.
  + **hours** - hours remaining before full discharge/charge (int).
  + **minutes** - minutes (without hours, 0 < m < 60) remaining before
    full discharge/charge (int).
  + **in_seconds** - seconds remaining before full discharge/charge,
    (int).

  Settings description:

  + **fmt_discharging** - format for *"Discharging"* battery state.
  + **fmt_charging** - format for *"Charging"* battery state.
  + **fmt_unknown** - format for *"Unknown"* battery state.
  + **fmt_warning** - format on warning state (see later).
  + **fmt_not_present** - format when battery isn't present.
  + **menu_theme** -- theme parameters for dropdown menu (displayed
    only when two or more batteries are available)
  + **bind_buttons** - bind default buttons or not (only for dropdown
    menu)
  + **show_popup** - show popup with battery info on click.
  + **popup_fmt** - format for info popup.
  + **warning_seconds** - remaining seconds value before entering to
    the warning state.
  + **refresh_timeout** - battery state refresh timeout.
  + **notify_warning** - notify about warnings with naughty.
  + **notify_warning_title** - title for warning notification popup.
  + **notify_warning_text** - text for warning notification popup.
