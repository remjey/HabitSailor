import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent.width
    height: Theme.paddingSmall * 2 + Math.max(
                collectItemKey.height,
                collectItemValue.height,
                collectItemContent.height)

    property string key;
    property string value;
    default property alias children: collectItemContent.data

    Label {
        id: collectItemKey
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width / 2 - Theme.paddingSmall
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        horizontalAlignment: Text.AlignRight
        text: key
    }

    Column {
        id: collectItemContent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width / 2 - Theme.paddingSmall
    }

    Label {
        id: collectItemValue
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width / 2 - Theme.paddingSmall
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        text: value
    }

}
