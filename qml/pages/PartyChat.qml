import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."

Page {
    id: root

    SilicaFlickable {
        id: page
        anchors.fill: parent
        contentHeight: parent.height

        PushUpMenu {
            id: pageMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: updateData();
            }
        }

        PageHeader {
            id: pageHeader
            width: parent.width
            title: qsTr("Your party’s chat")
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: pageMenu.busy && chatModel.count == 0
            size: BusyIndicatorSize.Large
        }

        SilicaListView {
            id: chatListView
            anchors.top: pageHeader.bottom
            anchors.bottom: chatSendItem.top
            anchors.bottomMargin: Theme.paddingMedium
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            VerticalScrollDecorator {}

            verticalLayoutDirection: "BottomToTop"

            model: chatModel

            delegate: ListItem {
                contentHeight: chatListContent.implicitHeight + Theme.paddingLarge
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.3
                    visible: !chatListContentName.visible
                }

                Column {
                    id: chatListContent
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    y: Theme.paddingLarge / 2

                    Label {
                        id: chatListContentName
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        horizontalAlignment: chatListContentText.horizontalAlignment
                        visible: model.fromType === "me" || model.fromType === "friend"
                        text: model.name
                        color: model.fromType === "friend" ? Theme.secondaryColor : Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    Text {
                        id: chatListContentText
                        width: parent.width - Theme.itemSizeMedium
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        text: model.text
                        font.pixelSize: model.fromType === "friend" ? Theme.fontSizeMedium : Theme.fontSizeSmall
                        textFormat: Text.RichText
                        x: {
                            switch (model.fromType) {
                            case "friend": return Theme.itemSizeMedium
                            case "me": return 0;
                            case "system":
                            default:
                                return Theme.itemSizeMedium / 2;
                            }
                        }
                        color: {
                            switch (model.fromType) {
                            case "friend": return Theme.primaryColor
                            case "me": return Theme.highlightColor;
                            case "system":
                            default:
                                return Theme.secondaryColor;
                            }
                        }
                        horizontalAlignment: {
                            switch (model.fromType) {
                            case "friend": return Text.AlignRight;
                            case "me": return Text.AlignLeft;
                            case "system":
                            default:
                                return Text.AlignHCenter;
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: chatSendItem
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingMedium
            width: parent.width
            height: chatTextField.height

            TextArea {
                id: chatTextField
                anchors.left: parent.left
                anchors.right: chatSendButton.left
                height: Math.min(Theme.itemSizeHuge, implicitHeight)

                labelVisible: false
                placeholderText: qsTr("Type your message here")

                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere

                property bool validMessage: text.trim().length > 0

                EnterKey.onClicked: sendMessage();
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            }

            IconButton {
                id: chatSendButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Theme.paddingSmall
                icon.source: "image://theme/icon-m-message?" + (pressed
                  ? Theme.highlightColor
                  : Theme.primaryColor)

                enabled: chatTextField.validMessage && !currentlyPosting

                property bool currentlyPosting: false

                onClicked: sendMessage();
            }
        }
    }

    ListModel { id: chatModel }

    Component.onCompleted: updateData();

    function sendMessage() {
        if (!chatTextField.validMessage) return;

        chatSendButton.currentlyPosting = true;
        Model.postChatMessage("party", chatTextField.text.trim(), function (ok, msg) {
            chatSendButton.currentlyPosting = false;
            if (ok) chatModel.insert(0, msg);
        });
        chatTextField.text = "";
    }

    function updateData() {
        pageMenu.busy = true;
        Model.getGroupData("party", function (ok, o) {
            if (!ok) return;

            chatModel.clear();
            pageMenu.busy = false;
            pageHeader.title = o.name;
            o.chat.forEach(function (msg) {
                chatModel.append(msg);
            })
            details = o;
            chatListView.opacity = true;
            updateDetailsPage();
        })
    }

    property var details: null;
    property var detailsPage: null;

    function updateDetailsPage() {
        if (!details) return;

        if (!detailsPage) detailsPage = pageStack.pushAttached("PartyDetails.qml", { details: details });
        else detailsPage.updateData(details);
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (!busy && pageStack.currentPage === root && !detailsPage) {
                updateDetailsPage();
            }
        }
    }
}
