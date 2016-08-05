import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    width: parent.width
    contentHeight: Theme.itemSizeSmall

    property url imageSource
    property string label

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.horizontalPageMargin
        spacing: Theme.paddingMedium
        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: root.imageSource
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}

