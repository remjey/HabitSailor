import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("../assets/habitica.png")
            opacity: 0.75
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "HabitSailor loading…"
            color: Theme.highlightColor
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: true
            size: BusyIndicatorSize.Large
        }

    }

}

