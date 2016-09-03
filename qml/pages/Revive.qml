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
import ".."

Dialog {
    id: root

    acceptDestination: revivePage
    onAccepted: {
        Model.revive(function () {
            pageStack.completeAnimation();
            pageStack.replaceAbove(null, Qt.resolvedUrl("Main.qml"));
        });
    }

    Flickable {
        anchors.fill: parent

        Column {
            anchors.fill: parent
            spacing: Theme.paddingLarge

            DialogHeader {
                dialog: root
                cancelText: qsTr("Cancel")
                acceptText: qsTr("Continue")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                wrapMode: Text.WordWrap
                text: qsTr("You ran out of Health!")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: Theme.highlightColor
                wrapMode: Text.WordWrap
                text: qsTr("Don’t despair, You lost a Level, your Gold, and a piece of Equipment, but you can get them all back with hard work! Good luck – you'll do great.")
            }

        }

    }

    Component {
        id: revivePage
        Page {
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge

                Label {
                    id: connectStatus
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Refilling your health")
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    anchors.topMargin: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

}

