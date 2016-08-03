import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property real value: 0
    property real maximum: 100
    property string label: ""
    property color barColor: Theme.highlightColor

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(value) + " / " + Math.round(maximum)
    }
    Bar {
        width: parent.width
        value: parent.value
        maximum: parent.maximum
        color: barColor
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: label
        color: Theme.secondaryHighlightColor
    }
}

