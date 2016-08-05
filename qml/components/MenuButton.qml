import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    width: parent.width
    height: root.subLabel ? (subLabelItem.y + subLabelItem.height + Theme.paddingMedium) : Theme.itemSizeSmall

    property url imageSource
    property string label
    property string subLabel

    Item {
        id: box
        anchors.fill: parent

        Image {
            id: imageItem
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: (Theme.itemSizeSmall - height) / 2
            anchors.leftMargin: Theme.horizontalPageMargin
            source: root.imageSource
        }

        Label {
            id: labelItem
            anchors.left: imageItem.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.verticalCenter: imageItem.verticalCenter
            text: root.label
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            id: subLabelItem
            anchors.left: labelItem.left
            anchors.top: labelItem.bottom
            text: root.subLabel
            visible: root.subLabel
            height: root.subLabel ? undefined : 0
            color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }

    }

    function remorse(message, cb) {
        remorseItem.execute(box, message, cb)
    }

    RemorseItem {
        id: remorseItem
    }
}

