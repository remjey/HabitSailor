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

    property bool reward: false
    property bool isDue: !reward
    property string subLabel: ""
    property bool busy: false
    property bool crossed: false
    property bool counters: false
    property bool compact: false

    Component.onCompleted: {
        if (model.missedDueDate) {
            redBackground.createObject(listItem);
        }
    }

    Component {
        id: redBackground
        Rectangle {
            z: -1;
            anchors.fill: parent;
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba("red", 0.15) }
                GradientStop { position: 1.0; color: Theme.rgba("red", 0.3) }
            }
            visible: model.missedDueDate && !listItem.highlighted
        }

    }

    Item {
        id: colorIndicatorWrapper
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall / 3
        visible: !reward

        Rectangle {
            id: colorIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.height
            height: parent.height
            color: isDue ? model.color : Qt.rgba(0, 0, 0, 0);
            opacity: !crossed && isDue ? 0.8 : 0.4
            border.width: isDue ? 0 : 2
            border.color: Theme.highlightColor
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Image {
            source: "image://theme/icon-s-clear-opaque-cross"
            anchors.centerIn: colorIndicator
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
        anchors.verticalCenter: parent.verticalCenter
        x: reward ? Theme.horizontalPageMargin : Theme.itemSizeSmall
        width: parent.width - x - Theme.horizontalPageMargin

        opacity: listItem.enabled ? ((reward || isDue && !crossed) ? 1 : 0.7) : 0.4 // Same as in TextSwitch

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
            visible: !!text && !compact
            color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            text: makeText(
                      subLabel, model.dueDateFormatted, model.startDateFormatted,
                      model.counterUp, model.counterDown)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall

            function makeText(subLabel, dueDate, startDate, cUp, cDown) {
                var r = []
                if (subLabel) r.push(subLabel);
                if (dueDate) r.push(qsTr("Due Date: %1").arg(dueDate));
                if (startDate) r.push(qsTr("Start Date: %1").arg(startDate));
                if (counters) r.push(qsTr("Streak: +%1 / −%2").arg(cUp).arg(cDown));
                return r.join("\n");
            }
        }
    }

}
