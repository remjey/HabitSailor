import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property bool preventBusyIndicator: false
    property bool animateOnLoaded: false

    property alias image: contentImage
    property alias busy: busyItem

    property alias source: contentImage.source
    property alias implicitHeight: contentImage.implicitHeight
    property alias implicitWidth: contentImage.implicitWidth
    property alias sourceSize: contentImage.sourceSize
    property alias fillMode: contentImage.fillMode

    Image {
        id: contentImage
        fillMode: Image.PreserveAspectFit
        width: parent.width
        height: parent.height
        opacity: !animateOnLoaded || status == Image.Ready ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } enabled: animateOnLoaded }
    }

    Behavior on height { NumberAnimation { duration: 200 } enabled: animateOnLoaded }
    Behavior on width { NumberAnimation { duration: 200 } enabled: animateOnLoaded }

    property int _minDimension: Math.min(width, height)

    BusyIndicator {
        id: busyItem
        anchors.centerIn: parent
        running: !preventBusyIndicator && contentImage.status == Image.Loading
        size: {
            if (_minDimension >= Theme.itemSizeLarge) return BusyIndicatorSize.Large;
            if (_minDimension >= Theme.itemSizeMedium) return BusyIndicatorSize.Medium;
            if (_minDimension >= Theme.itemSizeSmall) return BusyIndicatorSize.Small;
            return BusyIndicatorSize.ExtraSmall;
        }
    }

}
