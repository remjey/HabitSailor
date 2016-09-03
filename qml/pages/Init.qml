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
import "../components"
import ".."

Page {

    states: [
        State {
            name: "LOADING"
            PropertyChanges { target: busyCircle; visible: true; running: true }
            PropertyChanges { target: label; text: qsTr("HabitSailor Loading...") }
            PropertyChanges { target: retryBlock; visible: false }
        },
        State {
            name: "ERROR"
            PropertyChanges { target: busyCircle; visible: false; running: false }
            PropertyChanges { target: label; text: qsTr("HabitSailor could not connect to the server or received an unexpected error!") }
            PropertyChanges { target: retryBlock; visible: true }
        }
    ]

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("../assets/habitica.png")
            opacity: 0.75
        }

        Label {
            id: label
            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            color: Theme.highlightColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        BusyIndicator {
            id: busyCircle
            anchors.horizontalCenter: parent.horizontalCenter
            size: BusyIndicatorSize.Large
        }

        Column {
            id: retryBlock
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.horizontalPageMargin * 2
            spacing: Theme.paddingSmall

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: qsTr("Retry")
                onClicked: {
                    connect();
                }
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: qsTr("Change Login")
                onClicked: {
                    Model.logout();
                    pageStack.replace("Login.qml");
                }
            }
        }

    }

    function connect() {
        state = "LOADING";
        if (Model.isLogged()) {
            Model.update(function (ok) {
                if (ok)
                    pageStack.replace("Main.qml")
                else
                    state = "ERROR";
            });
        } else
            pageStack.replace("Login.qml")
    }

    Connections {
        target: Signals
        onStart: connect()
    }

}

