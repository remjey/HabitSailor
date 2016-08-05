import QtQuick 2.0
import Sailfish.Silica 1.0
import "../model.js" as Model

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
                cancelText: "Cancel"
                acceptText: "Continue"
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                wrapMode: Text.WordWrap
                text: "You ran out of Health!"
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: Theme.highlightColor
                wrapMode: Text.WordWrap
                text: "Don’t despair, You lost a Level, your Gold, and a piece of Equipment, but you can get them all back with hard work! Good luck – you'll do great."
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
                    text: "Refilling your health"
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

