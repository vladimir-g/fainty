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
    empty_tpl = '',
    active_callback = function (obj)
      return #obj.notifications ~= 0
    end,
    bind_buttons = true,
    refresh_timeout = 10
  }

  Description:

  + **active_tpl** - text when widget is in *active* state.
  + **empty_tpl** - text when widget is in *empty* state
  + **active_callback** - function to check widget state. Receives
    widget as argument (wgt.notifications - list of notifications
    where every item is table with *naughty.notify* args.
  + **bind_buttons** - bind buttons when widget is created
  + **refresh_timeout** - how frequently notifications state are
    checked. Widget tracks count of expired notifications.

  Available values for format in **active_tpl** and **empty_tpl**:

  + **count** - count of notifications.
  + **active** - count of non-expired notifications.
  + **expired** - count of expired notifications.
