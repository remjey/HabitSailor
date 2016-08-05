/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "model.js" as Model

ApplicationWindow
{
    initialPage: Qt.resolvedUrl("pages/Init.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
    _defaultPageOrientations: Orientation.Portrait

    Component.onCompleted: {
        messageBox.connectTo(Model.signals.showMessage)
        Model.init()
        if (Model.isLogged()) {
            Model.update(function (ok) {
                if (ok)
                    pageStack.replaceAbove(null, "pages/Main.qml", {})
            });
        } else
            pageStack.replace("pages/Login.qml")
    }

    Item {
        id: messageBox
        width: parent.width
        height: Theme.itemSizeMedium
        anchors.bottom: parent.bottom
        visible: true
        opacity: 0

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.75
        }

        Rectangle {
            width: parent.width
            height: Theme.paddingSmall
            anchors.top: parent.top
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
            duration: 100
            onStarted: { messageBox.visible = true; }
            from: 0
            to: 1
        }

        NumberAnimation on opacity {
            id: hideAnim
            running: false
            duration: 200
            onStopped: { messageBox.visible = false; }
            from: 1
            to: 0
        }

        Timer {
            id: hideTimer
            interval: 3000
            onTriggered: { hideAnim.start() }
        }

        function connectTo(signl) {
            signl.connect(show)
        }

        function show(msg) {
            msgLabel.text = msg;
            if (opacity != 1) {
                hideAnim.stop();
                showAnim.start();
            }
            hideTimer.restart();
        }
    }

}
