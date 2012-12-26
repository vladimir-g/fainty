====================================================
 Fainty - yet another widget library for awesome WM
====================================================

Fainty is the small and simple widget library for awesome WM. Goal of
this project - create a small subset of configurable widgets for
common needs. Library's widgets trying to be minimalistic and act like
standard awesome widgets.

This library requires awesome 3.5 and lua 5.2. Lua 5.1 may work but
not tested.

Why create another library?
===========================

The NIH syndrome ordered me to do so.

Widgets
=======

List of included widgets:

* **fainty.widgets.alsa** - ALSA volume widget that can control several
  channels of one or multiple audio cards.
* **fainty.widgets.kbdd** - Widget that displays and controls keyboard
  layouts with use of `kbdd <https://github.com/qnikst/kbdd/>`_.


Installation
============

Clone this repository and put fainty directory in your config path::

 cp -R fainty ${XDG_CONFIG_HOME}/awesome/

Add this to the top of your rc.lua::

 local fainty = require("fainty")

Usage
=====

Look to README.rst in *widgets* directory for full documentation.

