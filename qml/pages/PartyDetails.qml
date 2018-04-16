import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    property var details: null

    Component.onCompleted: updateData();

    function updateData(cdetails) {
        if (cdetails) details = cdetails;

        pageHeader.title = details.title;
    }

    SilicaFlickable {
        id: page
        anchors.fill: parent
        contentHeight: pageContent.implicitHeight

        VerticalScrollDecorator {}

        Column {
            id: pageContent
            width: parent.width

            PageHeader {
                id: pageHeader
                width: parent.width
                title: "Party Details"
            }
        }
    }
}
