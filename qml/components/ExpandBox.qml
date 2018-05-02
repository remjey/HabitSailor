import QtQuick 2.0

Item {
    id: root

    property bool expanded: false
    property real contentHeight: 0

    visible: height != 0
    width: parent.width
    height: expanded ? contentHeight : 0
    opacity: expanded ? 1 : 0

    Behavior on height { NumberAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

}
