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

Column {
    property real value: 0
    property real secondaryValue: 0
    property real maximum: 0
    property string label: ""
    property color barColor: Theme.highlightColor
    property color secondaryBarColor: Theme.secondaryHighlightColor

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.highlightColor
        text: (Math.floor(value) + (maximum <= 0 ? "" : " / " + Math.floor(maximum))
               + (secondaryValue != 0 ? " ( " + secondaryValue + " )" : ""))
    }
    Bar {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: maximum > 0
        width: parent.width - Theme.paddingLarge
        value: parent.value
        secondaryValue: Math.abs(parent.secondaryValue)
        maximum: parent.maximum
        color: barColor
        secondaryColor: secondaryBarColor
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: label
        color: Theme.secondaryHighlightColor
    }
}

