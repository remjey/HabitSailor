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

ListItem {
    id: listItem
    contentHeight: Math.max(labels.implicitHeight + 2 * Theme.paddingMedium, Theme.itemSizeSmall)

    property bool showColor: true
    property string subLabel: ""
    property bool busy: false
    property bool crossed: false

    Rectangle {
        anchors.fill: parent;
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba("red", 0.15) }
            GradientStop { position: 1.0; color: Theme.rgba("red", 0.3) }
        }
        visible: model.missedDueDate && !listItem.highlighted;
    }

    Item {
        id: colorIndicatorWrapper
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall / 3

        Rectangle {
            id: colorIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.height
            height: parent.height
            color: showColor ? model.color : Theme.highlightColor
            opacity: showColor ? 0.8 : 0.4
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Image {
            source: "image://theme/icon-s-clear-opaque-cross"
            anchors.centerIn: parent
            opacity: crossed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        SequentialAnimation on opacity {
            running: busy
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.2; duration: 500; }
            NumberAnimation { from: 0.2; to: 1.0; duration: 500; }
            onStopped: {
                colorIndicatorWrapper.opacity = 1;
            }
        }
    }

    Column {
        id: labels
        anchors.left: colorIndicatorWrapper.right
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        opacity: listItem.enabled ? (showColor ? 1 : 0.7) : 0.4 // Same as in TextSwitch

        Label {
            text: model.text
            width: parent.width
            maximumLineCount: 4
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: Text.ElideRight
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            width: parent.width
            visible: text
            color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            text: makeText(subLabel, model.dueDateFormatted, model.startDateFormatted)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall

            function makeText(subLabel, dueDate, startDate) {
                var r = []
                if (subLabel) r.push(subLabel);
                if (dueDate) r.push(qsTr("Due Date: %1").arg(dueDate));
                if (startDate) r.push(qsTr("Start Date: %1").arg(startDate));
                return r.join("\n");
            }
        }
    }

}
