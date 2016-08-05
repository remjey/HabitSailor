import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: listItem
    contentHeight: Math.max(listItemRow.height + 2 * Theme.paddingMedium, Theme.itemSizeSmall)

    property bool showColor: true
    property string subLabel: ""
    property bool hollowRect: false

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
            color: hollowRect ? "transparent" : model.color
            border.color: model.color
            border.width: Theme.paddingSmall
            opacity: showColor ? 0.8 : 0
        }

        Column {
            width: parent.width - x
            anchors.verticalCenter: parent.verticalCenter

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

}
