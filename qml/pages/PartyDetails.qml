import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

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
        }
    }
}
