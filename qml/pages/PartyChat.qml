import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."

Page {

    SilicaFlickable {
        id: page
        anchors.fill: parent

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: "Refresh"
                onClicked: update();
            }
        }

        PageHeader {
            id: pageHeader
            width: parent.width
            title: "Your party’s chat"
        }

        SilicaListView {
            anchors.top: pageHeader.bottom
            anchors.bottom: chatSendItem.top
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true

            VerticalScrollDecorator {}

            verticalLayoutDirection: "BottomToTop"

            model: chatModel

            delegate: ListItem {
                contentHeight: chatListContent.implicitHeight + Theme.paddingLarge
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.4
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

                    Label {
                        id: chatListContentText
                        width: parent.width - Theme.itemSizeMedium
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        text: model.text
                        font.pixelSize: model.fromType === "friend" ? Theme.fontSizeMedium : Theme.fontSizeSmall
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
            width: parent.width
            height: chatTextField.implicitHeight

            TextField {
                id: chatTextField
                anchors.left: parent.left
                anchors.right: chatSendButton.left

                labelVisible: false
                placeholderText: qsTr("Type your message here")

                property bool validMessage: text.trim().length > 0

                EnterKey.onClicked: sendMessage();
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            }

            IconButton {
                id: chatSendButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
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

    Component.onCompleted: update();

    function sendMessage() {
        if (!chatTextField.validMessage) return;

        chatSendButton.currentlyPosting = true;
        Model.postChatMessage("party", chatTextField.text.trim(), function (ok, msg) {
            chatSendButton.currentlyPosting = false;
            if (ok) chatModel.insert(0, msg);
        });
        chatTextField.text = "";
    }

    function update() {
        pullDownMenu.busy = true;
        chatModel.clear();
        Model.getGroupData("party", function (ok, o) {
            pullDownMenu.busy = false;
            pageHeader.title = o.name;
            o.chat.forEach(function (msg) {
                chatModel.append(msg);
            })
        })
    }
}
