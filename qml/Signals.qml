/*
  Copyright 2016 Jérémy Farnaud

  This file is part of HabitSailor.

  HabitSailor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  HabitSailor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Foobar.  If not, see <http://www.gnu.org/licenses/>
*/

pragma Singleton

import QtQuick 2.0

QtObject {

    signal applicationActive()

    signal start()
    signal logout()
    signal updateStats()
    signal updateTasks()
    signal updateNewMessages()
    signal showMessage(string msg)
    signal setTask(string taskId, bool checked)
    signal setSubtask(string taskId, string subtaskId, bool checked)

    signal bringToFront(string action)

    signal avatarPainted(var imageData)

}

