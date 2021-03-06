import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import ".."

Page {
    id: root

    property bool _loading: false

    Component.onCompleted: updateData();

    function updateData() {
        _loading = true;
        penpals.clear()
        Model.updateMessages(function (ok) {
            var nonloadedAvatars = [];
            Model.getPenpals().forEach(function (o) {
                o.hasAvatar = true;
                if (!o.avatar) nonloadedAvatars.push(o.userId);
                penpals.append(o);
            });
            _loading = false;
            nonloadedAvatars.forEach(function (userId) {
                Model.getMemberAvatar(userId, function (parts) {
                    for (var i = 0; i < penpals.count; ++i) {
                        if (penpals.get(i).userId === userId) {
                            if (parts) {
                                penpals.setProperty(i, "avatar", parts);
                            } else {
                                penpals.setProperty(i, "hasAvatar", false);
                            }
                        }
                    }
                });
            })
        });
    }

    ListModel {
        id: penpals
        dynamicRoles: true
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: _loading
        size: BusyIndicatorSize.Large
    }

    EmptyListHint {
        visible: !_loading && penpals.count == 0
        label: qsTr("No messages")
        subLabel: qsTr("Start a new conversation by selecting a member of your party")
    }

    SilicaListView {
        id: list
        anchors.fill: parent

        model: penpals
        delegate: penpalItemComponent

        VerticalScrollDecorator {}

        header: PageHeader { title: qsTr("Messages") }

        footer: Item { height: Theme.paddingLarge }
    }

    Component {
        id: penpalItemComponent

        ListItem {
            id: item
            width: parent.width
            contentHeight: avatarPanel.height
            opacity: 0

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Component.onCompleted: opacity = 1

            onClicked: {
                penpals.setProperty(model.index, "unread", 0);
                pageStack.push(Qt.resolvedUrl("Messages.qml"),
                               {
                                   userId: model.userId,
                                   title: model.name
                               });
            }

            PanelBackground {
                id: avatarPanel
                height: Theme.itemSizeLarge
                width: Theme.itemSizeLarge

                BusyIndicator {
                    anchors.centerIn: parent
                    running: !penpalAvatar.loaded && model.hasAvatar
                    size: BusyIndicatorSize.Small
                }

                Avatar {
                    id: penpalAvatar
                    anchors.fill: parent
                    parts: model.avatar
                    small: true

                    opacity: loaded ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            Label {
                id: penpalName
                anchors.left: avatarPanel.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter

                truncationMode: TruncationMode.Elide
                text: model.name
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            GlassItem {
                id: unreadMessagesGlassItem
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall
                radius: 1.0
                opacity: model.unread ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }
}
