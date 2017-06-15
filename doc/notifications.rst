==============================
 fainty.widgets.notifications
==============================

Notifications widget displays count of *naughty* notifications. Main
purpose is to store notifications data even when they missed when user
is away. Notifications list is reset on click.
Usage
=====

Create widget somewhere in the top of your rc.lua::

  notifywgt = fainty.widgets.notifications({})

Then add widget to layout like awful.widget.textbox::

  right_layout:add(notifywgt)

Customization
=============

Constructor looks like this::

  fainty.widgets.notifications({ settings = {...} })

Arguments:

* **settings**

  Optional table with widget settings. Defaults used if none provided.

  Example::

  {
    active_tpl = ' <span color="#F80000"><b>[%(count)s]</b></span> ',
    suspended_tpl = ' <span color="#7D79A9"><b>[%(count)s]</b></span> ',
    empty_tpl = ' <span><b>[%(count)s]</b></span> ',
    active_callback = function (obj)
      return #obj.notifications ~= 0
    end,
    bind_buttons = true,
    show_popup = true,
    show_expired = true,
    refresh_timeout = 10
  }

  Description:

  + **active_tpl** - text when widget is in *active* state.
  + **suspended_tpl** - text when *naughty* is suspended.
  + **empty_tpl** - text when widget is in *empty* state.
  + **active_callback** - function to check widget state. Receives
    widget as argument (wgt.notifications - list of notifications
    where every item is table with *naughty.notify* args. May be used
    when only expired notifications count matters or something else.
  + **bind_buttons** - bind buttons when widget is created
  + **show_popup** - show popup with notifications list.
  + **show_expired** - show text of expired notifications in popup.
  + **refresh_timeout** - how frequently notifications state are
    checked. Widget tracks count of expired notifications.

  Available values for format in **active_tpl**, **suspended_tpl** and
  **empty_tpl**:

  + **count** - count of notifications.
  + **active** - count of non-expired notifications.
  + **expired** - count of expired notifications.

Binded buttons by default: left mouse shows popup with all
notifications texts, right button clears notifications, middle button
toggles *naughty* suspend state.
