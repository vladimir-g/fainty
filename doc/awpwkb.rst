=======================
 fainty.widgets.awpwkb
=======================

This is simple widget for controlling `awpwkb
<https://github.com/vladimir-g/awpwkb/>`_ keyboard layout
switcher. Awpwkb instance must be initialized before using of widget,
consult with its documentation.

Default key bindings: select next layout with left mouse button,
select previous with middle, open dropdown with layouts with right
button.

Usage
=====

Import and initialize *awpwkb* with required options before creating
this widget, then create widget like this::

  local awpwkbwgt = fainty.widgets.awpwkb({})

Then add widget to some layout like standard textbox::

  s.mywibox:setup {
    -- ...
    awpwkbwgt
    -- ...
  }

Customization
=============

Widget's contstructor::

  fainty.widgets.awpwkb(settings)

Arguments:

* **fmt**

  Format for widget contents. Default::

    ' <b>[%(name)s]</b> '

  Available parameters:

  + **name** -- layout displayed name (see below)
  + **layout_index** -- layout index
  + **layout_name** -- layout original name


* **process_name**

  Function that called with layout original name and returns name that
  will be displayed. Can be used to replace some layout names with
  something. Default is nil. Example::

    local awpwkbwgt = fainty.widgets.awpwkb({
        process_name = function (name)
           if name == 'us' then return 'En' end
           return name:gsub("^%l", string.upper)
        end
    })

  This code initializes widget with custom **process_name** callback
  that capitalizes names and replaces "us" with "En".

* **bind_buttons**

  Bind default buttons for widget or not. Default is true.

* **menu_theme**

  Theme parameters for dropdown menu with layouts.

  Default is {width = 80, height = 15}
