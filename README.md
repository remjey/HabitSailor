# HabitSailor

## Intro

HabitSailor is a work-in-progress SailfishOS client for HabitRPG servers like Habitica.
It is meant to be imported int the QtCreator of the SailfishOS SDK.

HabitSailor is free software, released under GPLv3. Artwork is CC-BY-SA 3.0. (see LICENCE file for details)

## Why

Because the Android client is terribly slow and the website is too heavy for Jolla’s navigator.
Also I don’t like very much the Android emulation stack.

## Roadmap

Already working:

* Login/Logout
* Show basic profile info
* Display Habits, pressing on plus or minus
* Detects death, and show revive action from profile page
* Refresh action from pulley menu of profile screen
* Buy Health Potion
* To-Dos, Daily tasks with their subtasks, all checkable and uncheckable
* Gray out tasks that are not due today or not active yes, and redflag tasks due in the past, display due date

Most importantly and in approximate order:

* Use something like last cron date to compute state of tasks according to date constraints
* React gracefully when connection drops (already done to some extent)
* Automatic refresh, interval to be decided (when app returns active after long time? 1 hour period?)
* A useful cover
* About page
* Make it translation ready, with at least french translation

Some stuff that would be great in approximate order:

* Bring back todos from the dead (aka completed) state
* Filter tasks by tag, completed/not completed
* Sort tasks by color
* Other rewards (at least custom rewards and spells)
* Tasks editing, creation, deletion
* Social (team, guilds)


