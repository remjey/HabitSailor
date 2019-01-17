import QtQuick 2.0
import Sailfish.Silica 1.0

import "../utils.js" as Utils
import "../components"
import ".."

Page {
    id: root

    property alias title: pageHeader.title
    property string username
    property string userId

    ListModel { id: messages }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent

        PageHeader {
            id: pageHeader
        }

        SilicaListView {
            id: list
            anchors.top: pageHeader.bottom
            anchors.bottom: sendMessageBox.top
            width: parent.width
            clip: true
            model: messages

            VerticalScrollDecorator {}

            verticalLayoutDirection: "BottomToTop"

            delegate: ListItem {
                contentHeight: itemContent.implicitHeight + Theme.paddingLarge

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: model.loadId !== 0 ? 0.3 : 0
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
                    id: itemContent
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    y: Theme.paddingLarge / 2

                    Label {
                        id: chatListContentName
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        horizontalAlignment: chatListContentText.horizontalAlignment
                        text: model.mine ? Model.getName() : title
                        color: model.mine ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    Text {
                        id: chatListContentText
                        width: parent.width - Theme.itemSizeMedium
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        text: model.text
                        font.pixelSize: model.mine ? Theme.fontSizeSmall : Theme.fontSizeMedium
                        textFormat: Text.RichText
                        x: model.mine ? 0 : Theme.itemSizeMedium
                        color: model.mine ? Theme.highlightColor : Theme.primaryColor
                        horizontalAlignment: model.mine ? Text.AlignLeft : Text.AlignRight
                    }
                }
            }
        }

        SendMessageBox {
            id: sendMessageBox
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingMedium
            onSendMessage: doSendMessage()
        }

    }

    Component.onCompleted: {
        Model.getMessages(username).forEach(function (msg) {
            msg.loadId = 0; messages.append(msg)
        });
    }

    property int _msgLoadIdCounter: 0

    function doSendMessage() {
        var msgText = sendMessageBox.text.trim();
        var msgLoadId = ++_msgLoadIdCounter;

        sendMessageBox.currentlyPosting = true;
        messages.insert(0, {
                            id: "",
                            mine: true,
                            date: new Date(),
                            text: Utils.md(msgText),
                            unread: false,
                            loadId: msgLoadId,
                        });

        Model.postMessage(userId, msgText, function (ok, msg) {
            sendMessageBox.currentlyPosting = false;
            if (ok) {
                for (var i = 0; i < messages.count; ++i) {
                    if (messages.get(i).loadId === msgLoadId) {
                        messages.setProperty(i, "loadId", 0);
                        messages.setProperty(i, "id", msg.id);
                        messages.setProperty(i, "date", msg.date);
                        break;
                    }
                }
            } else {
                for (var i = 0; i < messages.count; ++i) {
                    if (messages.get(i).loadId === msgLoadId) {
                        messages.remove(i);
                        break;
                    }
                }
            }
        });
        sendMessageBox.text = "";
    }

}
