import QtQuick 2.0
import Sailfish.Silica 1.0
import "components"
import "model.js" as Model

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

    Item {
        id: messageBox
        width: parent.width
        height: Theme.itemSizeMedium
        anchors.bottom: parent.bottom
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
            msgLabel.text = msg;
            if (opacity != 1) {
                hideAnim.stop();
                showAnim.start();
            }
            hideTimer.restart();
        }

        SignalConnect {
            signl: Model.signals.showMessage
            fun: messageBox.showMessage
        }
    }

}
