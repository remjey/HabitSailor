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

Item {
    id: root
    height: Theme.itemSizeSmall / 2

    property real value: 0;
    property real secondaryValue: 0;
    property real maximum: 100;
    property color color: Theme.highlightColor
    property color secondaryColor: Theme.secondaryHighlightColor

    GlassItem {
        id: track
        anchors.centerIn: parent
        width: parent.width + parent.height - radius * 4
        height: parent.height

        color: root.color
        falloffRadius: 0.07
        radius: 3
        dimmed: true
        ratio: 0.0
        cache: false

        GlassItem {
            id: secondaryBar
            anchors.top: parent.top
            anchors.left: parent.left

            height: parent.height
            width: barWidth(parent.width, parent.height, root.secondaryValue, root.maximum) // To trigger the change of width through binding
            visible: root.secondaryValue > 0

            color: root.secondaryColor
            falloffRadius: 0.07
            radius: 3
            ratio: 0.0
            cache: false
        }

        GlassItem {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: barWidth(parent.width - parent.height, 0, root.secondaryValue, root.maximum)

            height: parent.height
            width: barWidth(parent.width, parent.height, root.value - Math.max(0, root.secondaryValue), root.maximum) // To trigger the change of width through binding
            visible: root.value > root.secondaryValue

            color: root.color
            falloffRadius: 0.07
            radius: 3
            ratio: 0.0
            cache: false
        }
    }

    function barWidth(width, height, value, maximum) {
        if (maximum <= 0 || value <= 0) return 0;
        if (value >= maximum) value = maximum;
        return height + Math.round((width - height) * value / maximum);
    }

}
