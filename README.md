# HabitSailor

## Intro

HabitSailor is a work-in-progress SailfishOS client for Habitica.
It is meant to be imported int the QtCreator of the SailfishOS SDK.

HabitSailor is free software, released under GPLv3. Artwork is CC-BY-SA 3.0. (see LICENCE file for details)

## Why

Because the Android client is terribly slow and the website is too heavy for Jolla’s navigator.
Also I don’t like very much the Android emulation stack.

## Roadmap

Working:

* Login/Logout
* Stay at Inn
* Show basic profile info
* Habits list, than can be upped or downed
* List of dailies and To-Dos with subtasks support, than can be all checked or unchecked
* Dailies and To-Dos date constraints are shown
* Detects death, and show revive action from profile page
* Buy Health Potion
* Covers that shows profile info or remaining uncompleted dailies

Most importantly and in approximate order:

* Add more data in the detailed view of tasks, edit, delete and create tasks
* React gracefully when connection drops (already done to some extent)
* Automatic refresh, interval to be decided (when app returns active after long time? 1 hour period?)
* About page
* Display notifications (and discard them from server?)

Some stuff that would be great in approximate order:

* Use data from user profile to build up-to-date profile picture instead of requesting a png profile picture (which may be old)
* Bring back todos from the dead (aka completed) state
* Filter tasks by tag, completed/not completed, add tag in task edit/creation
* Sort tasks by color
* Other rewards (at least custom rewards and spells)
* Social (team, guilds)


