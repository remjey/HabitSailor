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

Dialog {
    id: loginPage

    acceptDestination: connectPage

    onAccepted: {
        acceptDestinationInstance.setStatus(qsTr("Connecting"), true);
        if (useHabitica.checked) customHabitRpgUrl.text = ""
        Model.login(customHabitRpgUrl.text,
                    login.text,
                    password.text,
                    function () {
                        acceptDestinationInstance.setStatus(qsTr("Loading Profile"), true);
                        Model.update(function (ok) {
                            if (ok) {
                                pageStack.replaceAbove(null, Qt.resolvedUrl("Main.qml"));
                            } else {
                                acceptDestinationInstance.setStatus(qsTr("Impossible to retrieve profile data although the login and password are correct!"), false)
                            }
                        });
                    },
                    function (msg) {
                        acceptDestinationInstance.setStatus(msg, false)
                    });
    }

    canAccept: (login.text.trim() != ""
                && password.text != ""
                && (useHabitica || customHabitRpgUrl.text != "")
                )

    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width


            DialogHeader {
                dialog: loginPage
                acceptText: qsTr("Login")
                title: "HabitSailor"
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.highlightColor
                text: qsTr("Welcome to HabitSailor, an unofficial client for Habitica!")
            }

            SectionHeader {
                text: qsTr("Login")
            }

            TextSwitch {
                id: useHabitica
                text: qsTr("Use the Habitica.com server")
                description: qsTr("Uncheck only if you want to use a custom Habitica server")
                checked: true
            }

            Item {
                width: parent.width
                height: useHabitica.checked ? 0 : customHabitRpgUrl.implicitHeight
                clip: true
                Behavior on height { NumberAnimation { duration: 200 } }

                TextField {
                    id: customHabitRpgUrl
                    width: parent.width
                    label: qsTr("URL of the custom Habitica server")
                    placeholderText: label
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    // TODO validator

                    EnterKey.enabled: text.length > 2
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: login.focus = true
                }

            }

            TextField {
                id: login
                width: parent.width
                label: qsTr("Username or email address")
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: password.focus = true
            }

            PasswordField {
                id: password
                width: parent.width
                label: qsTr("Password")
                placeholderText: label
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: loginPage.accept()
            }

            SectionHeader {
                text: qsTr("About")
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                text: qsTr("HabitSailor is Free Software developped by Jérémy Farnaud and released under the GNU GPLv3 license.")
                color: Theme.highlightColor
                wrapMode: Text.WordWrap
            }

            MenuButton {
                imageSource: "image://theme/icon-m-about"
                label: qsTr("More Info")
                onClicked: pageStack.push("About.qml")
            }
        }
    }

    Component {
        // TODO prevent going back?
        id: connectPage
        Page {
            forwardNavigation: false
            function setStatus(text, working) {
                connectStatus.text = text
                connectBusy.running = working;
                connectBusy.visible = working;
                backNavigation = !working;
            }
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                width: parent.width

                Label {
                    id: connectStatus
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Connecting")
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    id: connectBusy
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

}

