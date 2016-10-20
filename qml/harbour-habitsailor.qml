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
import "components"
import "."

ApplicationWindow
{
    initialPage: Qt.resolvedUrl("pages/Init.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
    _defaultPageOrientations: Orientation.Portrait

    Component.onCompleted: {
        Model.init();
    }

    onApplicationActiveChanged: {
        // TODO refresh if we’ve been out too long?
    }

    Connections {
        target: Signals
        onShowMessage: messageBox.showMessage(msg)
        onBringToFront: {
            activate();
            if (action && pageStack.currentPage.stable) {
                pageStack.replaceAbove()
                if (action == "") {

                }
            }
        }
    }

    Item {
        id: messageBox
        width: parent.width
        height: Theme.itemSizeMedium
        anchors.top: parent.top
        visible: false
        opacity: 0

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.85
        }

        Rectangle {
            width: parent.width
            height: Theme.paddingSmall
            anchors.bottom: parent.bottom
            color: Theme.highlightBackgroundColor;
        }

        PanelBackground {
            anchors.fill: parent

            BackgroundItem {
                id: bgItem
                width: parent.width
                anchors.bottom: parent.bottom
                height: parent.height
                Label {
                    id: msgLabel
                    anchors.centerIn: parent
                    width: parent.width - Theme.horizontalPageMargin * 2
                    color: bgItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                }
                onClicked: {
                    hideTimer.stop()
                    hideAnim.start()
                }
            }
        }

        NumberAnimation on opacity {
            id: showAnim
            running: false
            duration: 200
            onStarted: { messageBox.visible = true; }
            from: 0
            to: 1
        }

        NumberAnimation on opacity {
            id: hideAnim
            running: false
            duration: 300
            onStopped: { messageBox.visible = false; }
            from: 1
            to: 0
        }

        Timer {
            id: hideTimer
            interval: 5000
            onTriggered: { hideAnim.start() }
        }

        function showMessage(msg) {
            // TODO show message at the top instead of the bottom?
            msgLabel.text = msg;
            if (opacity != 1) {
                hideAnim.stop();
                showAnim.start();
            }
            hideTimer.restart();
        }
    }

}
