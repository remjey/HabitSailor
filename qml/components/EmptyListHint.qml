import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    spacing: Theme.paddingSmall

    property alias label: labelItem.text
    property alias subLabel: subLabelItem.text

    Label {
        id: labelItem
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: Theme.fontSizeExtraLarge
        color: Theme.highlightColor
        text: qsTr("No Items")
    }
    Label {
        id: subLabelItem
        x: Theme.horizontalPageMargin
        width: parent.width - Theme.horizontalPageMargin * 2
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeMedium
        text: qsTr("Pull down to create a new one")
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
