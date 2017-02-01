====================================================
 Fainty - yet another widget library for awesome WM
====================================================

Fainty is small widget library for the `Awesome WM`_. It is not very
modular or extensible, has no external dependencies and provides
text-based widgets that look and behave like standard awesome widgets.

This library requires awesome 3.5 and don't work on 4.0 at this
time. Sorry.

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


.. _Awesome WM: http://awesome.naquadah.org/
.. _kbdd: https://github.com/qnikst/kbdd/
.. _doc: doc/

