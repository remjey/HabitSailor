import QtQuick 2.0
import Sailfish.Silica 1.0

import "../utils.js" as Utils
import "../components"
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
                    opacity: !chatListContentName.visible || model.loadId !== 0 ? 0.3 : 0
                    visible: opacity != 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                BusyIndicator {
                    running: model.loadId !== 0
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    size: BusyIndicatorSize.Small
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

        SendMessageBox {
            id: chatSendItem
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingMedium
            onSendMessage: doSendMessage()
        }
    }

    ListModel { id: chatModel }

    Component.onCompleted: updateData();

    function doSendMessage() {
        var msgText = chatSendItem.text.trim();
        var msgLoadId = ++_msgLoadIdCounter;

        chatSendItem.currentlyPosting = true;
        chatModel.insert(0, {
                             name: Model.getName(),
                             text: Utils.md(msgText),
                             fromType: "me",
                             loadId: msgLoadId,
                         });

        Model.postChatMessage("party", msgText, function (ok, msg) {
            chatSendItem.currentlyPosting = false;
            if (ok) {
                var found = false;
                for (var i = 0; i < chatModel.count; ++i) {
                    if (chatModel.get(i).loadId === msgLoadId) {
                        found = true;
                        chatModel.setProperty(i, "loadId", 0);
                        break;
                    }
                }
                if (!found) chatModel.insert(0, msg);
            } else {
                for (var i = 0; i < chatModel.count; ++i) {
                    if (chatModel.get(i).loadId === msgLoadId) {
                        chatModel.remove(i);
                        break;
                    }
                }
            }
        });
        chatSendItem.text = "";
    }

    function updateData() {
        pageMenu.busy = true;
        Model.getGroupData("party", function (ok, o) {
            if (!ok) return;

            chatModel.clear();
            pageMenu.busy = false;
            pageHeader.title = o.name;
            o.chat.forEach(function (msg) {
                msg.loadId = 0;
                chatModel.append(msg);
            })
            details = o;
            chatListView.opacity = true;
            updateDetailsPage();
        })
    }

    property var details: null;
    property var detailsPage: null;
    property int _msgLoadIdCounter: 0;

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
