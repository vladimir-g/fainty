=====================
 fainty.widgets.kbdd
=====================

This is widget for controlling `kbdd
<https://github.com/qnikst/kbdd/>`_ keyboard layout daemon. Kbdd of
course required.

Default key bindings: select next layout with left mouse button, open
dropdown with layouts with right button.

Usage
=====

Create widget somewhere in the top of your rc.lua, but after
beautiful.init (for proper dropdown menu styling)::

  local kbddwidget = fainty.widgets.kbdd({
      {label = "[En]", index = 0, name = "English"},
      {label = "[Ru]", index = 1, name = "Russian"} 
  })

Only supplied layouts will be used in widget's methods like
**next_layout** or **prev_layout**. An example: if you there are
layouts *0*, *1* and *2*, widget initialized only with layouts *0* and
*2*, method **next_layout** will skip through *1*.

Then add widget to layout like standard awful.widget.textbox::

  right_layout:add(kbddwidget)


Customization
=============

Widget's contstructor::

  fainty.widgets.kbdd(layout_list, settings)

Arguments:

* **layout_list**

  Table of layouts available for widget. Example::
  
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

    {
      menu_theme = { width = 80, height = 15 },
      dont_bind_buttons = false,
      error_msg = '<span color="#FF0004">[#]</span>'
    }

  Description:
  
  + **menu_theme** -- theme parameters for dropdown menu
  + **dont_bind_buttons** -- don't bind buttons when widget is created
  + **error_msg** -- text displayed on widget on error
