import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import ".."

Page {
    id: root

    property var details: null

    Component.onCompleted: updateData();

    function updateData(cdetails) {
        if (cdetails) details = cdetails;

        pageHeader.title = details.title;

        questItem.visible = !!details.quest;
        if (!!details.quest) {
            questName.text = details.quest.name;
            questPicture.source = details.quest.iconSource;

            questNotStarted.visible = !details.quest.active;
            collectRepeater.visible = details.quest.active && details.quest.type === "collect";
            health.visible = details.quest.active && details.quest.type === "boss";

            collectRepeater.model.clear();
            if (details.quest.active) {
                if (details.quest.type === "collect") {
                    details.quest.collect.forEach(function (ci) { collectRepeater.model.append(ci); });
                } else if (details.quest.type === "boss") {
                    health.value = details.quest.hp;
                    health.maximum = details.quest.maxHp;
                }
            }
        }
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

            Column {
                id: questItem
                width: parent.width

                SectionHeader {
                    text: "Quest"
                }

                Image {
                    id: questPicture
                    width: parent.width - Theme.itemSizeMedium * 2
                    height: implicitHeight * width / implicitWidth
                    x: Theme.itemSizeMedium
                }

                Item { height: Theme.paddingLarge; width: 1 }

                Label {
                    id: questName
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                }

                Item {
                    id: questNotStarted
                    width: parent.width
                    height: Theme.itemSizeMedium

                    Label {
                        anchors.fill: parent
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.italic: true
                        text: qsTr("Not started yet")
                    }
                }

                Item { height: Theme.paddingLarge; width: 1 }

                Stat {
                    id: health
                    width: parent.width
                    label: qsTr("Health")
                    barColor: "#da5353"
                }
/*
                Item {
                    id: healthItem
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin

                    Label {
                        id: healthLabel
                        text: "HP"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    Bar {
                        id: health;
                        anchors.left: healthLabel.right
                        anchors.right: parent.right
                        height: healthLabel.height
                        color: "#da5353"
                    }

                }
*/
                Repeater {
                    id: collectRepeater
                    model: ListModel {}

                    delegate: Item {
                        width: parent.width - Theme.horizontalPageMargin * 2
                        x: Theme.horizontalPageMargin
                        height: collectItemName.implicitHeight

                        Label {
                            id: collectItemName
                            width: parent.width / 2 - Theme.paddingSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignRight
                            text: model.name
                        }

                        Label {
                            id: collectItemCount
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width / 2 - Theme.paddingSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                            text: model.count + " / " + model.max
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Party members")
            }

            Repeater {
                id: membersRepeater
                model: ListModel {}
                delegate: Item {
                    width: parent.width - Theme.horizontalPageMargin
                    height: Math.max(memberAvatar.height, memberDetails.height)

                    Avatar {
                        id: memberAvatar
                        anchors.verticalCenter: parent.verticalCenter
                        parts: model.parts
                        height: Theme.itemSizeLarge
                        width: height
                        small: true

                        opacity: loaded ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    Item {
                        id: memberDetails
                        anchors.left: memberAvatar.right
                        anchors.leftMargin: Theme.paddingMedium
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: memberName.implicitHeight + barRow.implicitHeight

                        Label {
                            id: memberName
                            anchors.left: parent.left
                            anchors.right: memberLevel.right
                            anchors.rightMargin: Theme.paddingMedium
                            truncationMode: TruncationMode.Elide
                            text: model.name
                            color: Theme.highlightColor
                        }

                        Label {
                            id: memberLevel
                            anchors.right: parent.right
                            anchors.verticalCenter: memberName.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall
                            text: qsTr("Lv. %1").arg(model.level)
                            color: Theme.secondaryHighlightColor
                        }

                        Row {
                            id: barRow
                            anchors.top: memberName.bottom
                            anchors.left: parent.left

                            spacing: Theme.paddingMedium

                            Bar {
                                width: (memberDetails.width - barRow.spacing * 2) / 3
                                color: "#da5353"
                                value: model.hp
                                maximum: model.hpMax
                                height: Theme.itemSizeSmall / 3
                            }

                            Bar {
                                width: (memberDetails.width - barRow.spacing * 2) / 3
                                color: "#ffcc35"
                                value: model.xp
                                maximum: model.xpNext
                                height: Theme.itemSizeSmall / 3
                            }

                            Bar {
                                width: (memberDetails.width - barRow.spacing * 2) / 3
                                color: "#4781e7"
                                value: model.mp
                                maximum: model.mpMax
                                height: Theme.itemSizeSmall / 3
                            }
                        }
                    }
                }
            }

            BusyIndicator {
                id: membersBusy
                running: false
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Medium
            }
        }
    }

    function updateMembers() {
        membersBusy.running = true;
        membersRepeater.model.clear();
        Model.getGroupMembers(details.id, function (ok, o) {
            membersBusy.running = false;
            if (ok)
                o.forEach(function (item) { membersRepeater.model.append(item); });
        });
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (!busy && pageStack.currentPage === root) {
                updateMembers();
            }
        }
    }
}
