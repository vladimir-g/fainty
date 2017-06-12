====================================================
 Fainty - yet another widget library for awesome WM
====================================================

Fainty is small widget library for the `Awesome WM`_. It is not very
modular or extensible, has no external dependencies and provides
text-based widgets that look and behave like standard awesome widgets.

This library requires awesome 4.0. Last working version for 3.5 could
be found at v3.5 tag.

Warning: this is small one-man project without stable API, and beware
of bad English.

Why create another library?
===========================

The NIH syndrome.

Widgets
=======

List of included widgets:

* **fainty.widgets.alsa** - ALSA volume widget that can manage several
  channels of one or multiple sound cards.
* **fainty.widgets.kbdd** - Widget that displays and controls keyboard
  layouts with use of kbdd_.
* **fainty.widgets.awpwkb** - Widget for awpwkb_ per-window keyboard
  layout switcher.
* **fainty.widgets.calendar** - Textclock with calendar popup.
* **fainty.widgets.battery** - Widget with battery information.
* **fainty.widgets.pulseaudio** - PulseAudio widget that can control
  sources and sinks volume and muted state.
* **fainty.widgets.notifications** - Widget that displays
  notifications count.


Installation
============

Clone this repository and put fainty directory in your config path::

 cp -R fainty ${XDG_CONFIG_HOME}/awesome/

Add this to the top of your rc.lua::

 local fainty = require("fainty")

Usage
=====

Look to documentation in doc_ subdirectory.

Screeenshots
============

.. image:: https://i.imgur.com/wUsybSz.png

License
=======

This library released under MIT license, see LICENSE for more detail.


.. _Awesome WM: https://awesomewm.org/
.. _kbdd: https://github.com/qnikst/kbdd/
.. _awpwkb: https://github.com/vladimir-g/awpwkb/
.. _doc: doc/

