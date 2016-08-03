import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    height: Theme.itemSizeSmall / 2

    property real value: 0;
    property real maximum: 100;
    property color color: Theme.highlightColor

    GlassItem {
        id: slidertrack
        anchors.centerIn: parent
        width: parent.width - Theme.paddingSmall
        height: parent.height

        color: root.color
        falloffRadius: 0.07
        radius: 3
        dimmed: true
        ratio: 0.0
        cache: false

        GlassItem {
            anchors.top: parent.top
            anchors.left: parent.left
            height: parent.height
            width: height + Math.floor((parent.width - height) * root.value / root.maximum)
            visible: root.value > 0

            color: root.color
            falloffRadius: 0.07
            radius: 3
            ratio: 0.0
            cache: false
        }
    }

}
