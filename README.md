# HabitSailor

## Intro

HabitSailor is a work-in-progress Habitica client for SailfishOS developped by Jérémy Farnaud.
It will progressively implement features of the API starting with the most important ones.
As it is not yet complete, it can be seen as a sidekick to the main web application.

HabitSailor is Free Software, released under GPLv3. Artwork is CC-BY-SA 3.0. (see LICENCE file for details)

You can help me work on this project by donating:

* <a href="https://liberapay.com/remjey/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a>
* <a href="https://ko-fi.com/remjey"><img alt="Donate using Ko-Fi" src="https://www.ko-fi.com/img/Kofi_Logo_Blue.svg"></a>
* <a href="https://flattr.com/submit/auto?fid=mydw6m&amp;url=http%3A%2F%2Fjf.almel.fr%2Fflattr%2FHabitSailor" target="_blank"><img src="http://button.flattr.com/flattr-badge-large.png" alt="Flattr this" title="Flattr this" border="0"></a>
* BitCoin: <a href="bitcoin:1EVSFUTPCVXuTXEaAkowggToZgAS7ReZg5?label=HabitSailor">1EVSFUTPCVXuTXEaAkowggToZgAS7ReZg5</a>
* <a href="http://jf.almel.fr/paypal/HabitSailor">PayPal</a>

You can import the project in the QtCreator that comes with SailfishOS SDK.

If you feel like something important is missing, have an exciting idea, or a bug report,
go ahead and post a feature request on the [GitHub repository page](https://github.com/remjey/HabitSailor)!

## Why

Because the Android client is terribly slow and the website is too heavy for Jolla Phone’s navigator.
Also I don’t like very much the Android emulation stack, and I love the way SailfishOS interfaces work.

## Features

* View your profile general info, send and receive private messages
* View the lists of your habits, dailies and active todos with their status and checklists
* Click plus, minus on your habits, check your dailies and todos, update their checklists
* Create, edit and delete habits, dailies, todos (although setting value, tags and aliases is not yet implemented)
* The cover shows your stats and remaining dailies and todos, and an indicator for new messages
* Rest in the inn
* Buy health potion, custom reward, revive if you run out of health
* Cast skills
* Party: chat, list of members, actions on current quest, invite party to a quest
* Use a custom Habitica server

## Roadmap

### High Priority

* Add more data in the detailed view of tasks
* React gracefully when connection drops (already done to some extent)
* Automatic refresh, interval to be decided (when app returns active after long time? 1 hour period?)
* Display notifications (and discard them from server?)

### Lower Priority

* Bring back todos from the dead (aka completed) state
* Filter tasks by tag, completed/not completed, add tag in task edition/creation
* Sort tasks by color
* Other rewards
* More languages

