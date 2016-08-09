import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: listItem
    contentHeight: Math.max(labels.height + 2 * Theme.paddingMedium, Theme.itemSizeSmall)

    property bool showColor: true
    property string subLabel: ""
    property bool busy: false
    property bool crossed: false

    Rectangle {
        anchors.fill: parent;
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba("red", 0.1) }
            GradientStop { position: 1.0; color: Theme.rgba("red", 0.2) }
        }
        visible: model.missedDueDate && !listItem.highlighted;
    }

    Item {
        id: colorIndicatorWrapper
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall / 3

        Rectangle {
            id: colorIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.height
            height: parent.height
            color: showColor ? model.color : Theme.highlightColor
            opacity: showColor ? 0.8 : 0.4
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Image {
            source: "image://theme/icon-s-clear-opaque-cross"
            anchors.centerIn: parent
            opacity: crossed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        SequentialAnimation on opacity {
            running: busy
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.2; duration: 500; }
            NumberAnimation { from: 0.2; to: 1.0; duration: 500; }
            onStopped: {
                colorIndicatorWrapper.opacity = 1;
            }
        }
    }

    Column {
        id: labels
        anchors.left: colorIndicatorWrapper.right
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        opacity: listItem.enabled ? (showColor ? 1 : 0.7) : 0.4 // Same as in TextSwitch

        Label {
            text: model.text
            width: parent.width
            maximumLineCount: 4
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: Text.ElideRight
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            width: parent.width
            visible: text
            color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            text: subLabel + (model.dueDate ? (subLabel ? "\n" : "") + "Due date: " + model.dueDate : "")
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    RemorseItem {
        id: remorseItem
    }

    function remorse(msg, cb) {
        remorseItem.execute(listItem, msg, cb);
    }

}
