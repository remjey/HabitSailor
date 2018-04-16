import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    SilicaListView {
        anchors.fill: parent
        VerticalScrollDecorator {}

        header: Item {
            width: parent.width
            height: chatTextField.implicitHeight

            TextField {
                id: chatTextField
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right //TODO

                labelVisible: false
                placeholderText: qsTr("Your party’s chat")
            }
        }

        verticalLayoutDirection: ListView.BottomToTop

        model: ListModel {
            ListElement { text: "1" }
            ListElement { text: "2" }
            ListElement { text: "3" }
        }

        delegate: ListItem {
            contentHeight: theLabel.implicitHeight + Theme.paddingLarge
            Label {
                id: theLabel
                width: parent.width - Theme.horizontalPageMargin * 2
                y: Theme.paddingLarge / 2
                x: Theme.horizontalPageMargin
                text: model.text
            }
        }


    }

}
