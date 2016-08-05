import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property bool imageDown: false
    height: parent.height
    Image {
        anchors.centerIn: parent
        source: imageDown ? "image://theme/icon-m-remove" : "image://theme/icon-m-add"
        width: Theme.itemSizeMedium
        height: width
    }
}
