import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: listItem
    contentHeight: Math.max(listItemRow.height + 2 * Theme.paddingMedium, Theme.itemSizeSmall)

    property bool showColor: true
    property string subLabel: ""
    property bool hollowRect: false
    property bool busy: false

    Row {
        id: listItemRow
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.horizontalPageMargin
        spacing: Theme.paddingLarge

        Rectangle {
            id: colorIndicator
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.itemSizeSmall / 3
            height: width
            border.color: showColor ? model.color : Theme.highlightDimmerColor
            color: hollowRect ? "transparent" : border.color
            border.width: Theme.paddingSmall
            opacity: defaultOpacity(showColor)

            function defaultOpacity(showColor) {
                return showColor ? 0.8 : 0;
            }

            SequentialAnimation on opacity {
                running: busy && showColor
                loops: Animation.Infinite
                NumberAnimation { from: 0.2; to: 0.8; duration: 500; }
                NumberAnimation { from: 0.8; to: 0.2; duration: 500; }
                onStopped: {
                    colorIndicator.opacity = colorIndicator.defaultOpacity(showColor);
                }
            }
        }

        Column {
            width: parent.width - x
            anchors.verticalCenter: parent.verticalCenter
            opacity: listItem.enabled ? 1 : 0.4 // Same as in TextSwitch

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
                visible: subLabel
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: subLabel
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
            }
        }

    }

    RemorseItem {
        id: remorseItem
    }

    function remorse(msg, cb) {
        remorseItem.execute(listItem, msg, cb);
    }

}
