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

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge
        VerticalScrollDecorator { }
        Column {
            id: content
            width: parent.width

            PageHeader {
                title: qsTr("About HabitSailor")
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                color: Theme.highlightColor
                text: qsTr("HabitSailor is Free Software developped by Jérémy Farnaud and released under the GNU GPLv3 license.")
                wrapMode: Text.WordWrap
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                color: Theme.highlightColor
                text: qsTr("The Habitica logo and HabitSailor icon are licensed under the CC-BY-NC-SA 3.0. The HabitSailor icon is a derivative work of the Habitica logo.")
                wrapMode: Text.WordWrap
            }

            SectionHeader {
                text: qsTr("Links")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-link"
                label: qsTr("HabitSailor GitHub Repository")
                onClicked: Qt.openUrlExternally("https://github.com/remjey/HabitSailor")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-mail"
                label: qsTr("Contact %1").arg("Jérémy Farnaud")
                onClicked: Qt.openUrlExternally("mailto:jf@almel.fr")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-link"
                label: "GNU GPLv3"
                onClicked: Qt.openUrlExternally("http://www.gnu.org/licenses/gpl-3.0-standalone.html")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-link"
                label: "CC-BY-NC-SA 3.0"
                onClicked: Qt.openUrlExternally("http://creativecommons.org/licenses/by-nc-sa/3.0/")
            }

            SectionHeader {
                text: qsTr("Licenses")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-document"
                label: "GNU GPLv3"
                onClicked: pageStack.push(licensePage, { title: label, source: Qt.resolvedUrl("../assets/gpl-3.0-standalone.html") })
            }
        }
    }

    Component {
        id: licensePage
        Page {
            id: licensePageRoot
            property string title
            property string source
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height + Theme.paddingLarge
                VerticalScrollDecorator {}
                Column {
                    id: content
                    width: parent.width
                    PageHeader {
                        title: licensePageRoot.title
                    }
                    TextEdit {
                        id: textDisplay
                        width: parent.width - Theme.horizontalPageMargin * 2
                        height: implicitHeight
                        x: Theme.horizontalPageMargin
                        readOnly: true
                        textFormat: TextEdit.AutoText
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.highlightColor
                    }
                }
            }
            Component.onCompleted: {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function () {
                    if (xhr.readyState == 4) {
                        textDisplay.text = xhr.responseText
                    }
                }
                xhr.open("get", source);
                xhr.send()
            }
        }
    }
}

