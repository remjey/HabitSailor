import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."
import "../components"

Page {
    property var quest: ({})

    ListModel { id: collectibles }
    ListModel { id: rewards }

    onQuestChanged: {
        collectibles.clear();
        quest.collect.forEach(function (c) { collectibles.append(c); });
        rewards.clear();
        quest.rewards.forEach(function (r) { rewards.append(r); });
    }

    function startQuest() {
        flickable.enabled = false
        busyIndicator.running = true
        Model.startQuest(quest.key, function (ok) {
            if (ok) {
                var pdpage = pageStack.find(function (page) {
                    return page.pageName === "PartyDetails"
                });
                pageStack.pop(pdpage);
            } else {
                flickable.enabled = true
                busyIndicator.running = false
            }
        });
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: content.implicitHeight + Theme.paddingLarge
        opacity: enabled ? 1.0 : 0.5

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Start quest")
                onClicked: startQuest()
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Start quest")
                onClicked: startQuest()
            }
        }

        Column {
            id: content
            width: parent.width

            PageHeader { title: qsTr("Quest Details") }

            ImageWithBusyIndicator {
                x: Theme.itemSizeLarge
                width: parent.width - x * 2
                height: Math.max(Theme.itemSizeLarge, implicitHeight * width / implicitWidth || 0)
                animateOnLoaded: true
                source: quest.pictureSource
                fillMode: Image.PreserveAspectCrop
            }

            Item { height: Theme.paddingLarge; width: 1 }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeMedium
                text: quest.name
            }

            Item { height: Theme.paddingLarge; width: 1 }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignJustify
                font.pixelSize: Theme.fontSizeSmall
                text: quest.desc
            }

            Column {
                width: parent.width
                visible: quest.type === "collect"

                SectionHeader {
                    text: qsTr("Items to collect")
                }

                Repeater {
                    id: collectRepeater
                    model: collectibles

                    delegate: KeyValueItem {
                        x: Theme.horizontalPageMargin
                        width: parent.width - Theme.horizontalPageMargin * 2
                        key: model.name
                        value: model.max
                    }
                }
            }

            Column {
                width: parent.width
                visible: quest.type === "boss"

                SectionHeader {
                    text: qsTr("Boss Statistics")
                }

                KeyValueItem {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    key: qsTr("Health")
                    value: quest.maxHp
                }

                KeyValueItem {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    key: qsTr("Strength")
                    Item {
                        width: base.width * 0.6
                        height: base.height * 0.6
                        scale: 0.6
                        transformOrigin: Item.TopLeft

                        Image {
                            id: base
                            clip: true
                            fillMode: Image.Tile
                            width: 4 * sourceSize.width
                            height: sourceSize.height
                            horizontalAlignment: Image.AlignLeft
                            verticalAlignment: Image.AlignTop
                            source: "image://theme/icon-m-favorite?" + Theme.highlightColor
                        }
                        Image {
                            clip: true
                            fillMode: Image.Tile
                            width: quest.str * sourceSize.width// * height / paintedHeight
                            height: sourceSize.height
                            horizontalAlignment: Image.AlignLeft
                            verticalAlignment: Image.AlignTop
                            source: "image://theme/icon-m-favorite-selected?" + Theme.highlightColor
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Rewards")
            }

            Repeater {
                model: rewards
                delegate: Item {
                    width: parent.width
                    height: Math.max(Theme.iconSizeMedium, rewardText.height)

                    Item {
                        id: rewardImageItem
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        ImageWithBusyIndicator {
                            anchors.centerIn: parent
                            width: {
                                switch (model.iconZoom) {
                                case -1: return Theme.iconSizeSmall;
                                case 1: return Theme.iconSizeLarge;
                                default: return Theme.iconSizeMedium;
                                }
                            }
                            height: sourceSize.height * width / sourceSize.width
                            source: model.iconSource
                        }
                    }
                    Label {
                        id: rewardText
                        anchors.verticalCenter: parent.verticalCenter
                        x: rewardImageItem.x + rewardImageItem.width + Theme.paddingMedium
                        width: parent.width - x - Theme.horizontalPageMargin
                        color: Theme.highlightColor
                        text: model.text
                        wrapMode: "WrapAtWordBoundaryOrAnywhere"
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}
