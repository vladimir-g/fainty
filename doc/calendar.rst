=========================
 fainty.widgets.calendar 
=========================

This is widget that behaves like a standard awesome textclock with
calendar popup.

Calendar implemented in lua, month and day names localization
available with use of os locale function.

Default key bindings: left mouse opens calendar, scroll wheel displays
previous/next month when calendar is opened, middle click resets
calendar to current month (also when opened). Left click on calendar
closes it.

Usage
=====

Create widget somewhere in the top of your rc.lua::

  calendar = fainty.widgets.calendar({
        fmt = " %a %d %b <b>%H:%M:%S</b> ",
        timeout = 1,
        settings = { locale = 'ru_RU.UTF-8' }
  })

Then add widget to layout like awful.widget.textbox::

  right_layout:add(calendar)


Customization
=============

Constructor::

  fainty.widgets.calendar({ fmt = "...", timeout = 1, settings = {...} })


Arguments:

* **fmt**

  awful.widget.textclock time format.

* **timeout**

  awful.widget.textclock refresh timeout.

* **settings**

  Optional table with widget settings. Defaults::

    {
      week_start = 1,
      day_fmt = "<u><b>%s</b></u>",
      locale = nil,
      other_month_color = 'gray',
      show_other_month = true,
      bind_buttons = true
    }

  Description:

  + **week_start** - week start day. 0 - Sunday, 6 - Saturday.
  + **day_fmt** - how current day would be highlighted in the calendar.
  + **locale** - locale for month and day names. Widget changes locale
    with use of os.setlocale call on init and sets old locale after.
  + **other_month_color** - color for dates from other month, look to
    *show_other_month*.
  + **show_other_month** - show other month dates (*29*, *30*, *31*, 1, ...,
    31, *1*, *2*).
  + **bind_buttons** - bind default buttons or not.
