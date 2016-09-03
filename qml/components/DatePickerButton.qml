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

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../model.js" as Model

ValueButton {
    property var selectedDate: null
    property var defaultDate: null
    property bool canClear: false

    function openDateDialog() {
        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: selectedDate || defaultDate
                     })

        dialog.accepted.connect(function() {
            selectedDate = dialog.date
        })
    }

    value: selectedDate ? Model.formatDate(selectedDate) : qsTr("none")
    width: parent.width
    onClicked: {
        openDateDialog()
    }

    IconButton {
        visible: canClear && selectedDate
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        icon.source: "image://theme/icon-m-clear"

        onClicked: selectedDate = null
    }
}
