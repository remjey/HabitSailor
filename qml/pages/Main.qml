
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: "Log out"
                onClicked: {
                    remorse.execute("Logging out", function () {
                        Model.logout();
                        pageStack.replaceAbove(null, Qt.resolvedUrl("Login.qml"));
                    });
                }
            }
            MenuItem {
                text: "Settings"
            }
            MenuItem {
                text: "Refresh"
            }
        }

        RemorsePopup { id: remorse }

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: "HabitSailor"
            }

            SectionHeader {
                text: "Profile"
            }

            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    spacing: Theme.paddingMedium

                    Image {
                        id: profilePicture
                        width: Math.min(root.width / 2.5, Theme.itemSizeExtraLarge * 3)
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true;
                    }

                    Column {
                        width: parent.width - profilePicture.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            id: profileName
                            width: parent.width
                            height: Theme.itemSizeExtraSmall

                            font.pixelSize: Theme.fontSizeLarge
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            width: parent.width

                            Column {
                                width: parent.width / 2
                                Label {
                                    id: gems
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "-"
                                }
                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Gems"
                                    color: Theme.secondaryHighlightColor
                                }
                            }

                            Column {
                                width: parent.width / 2
                                Label {
                                    id: gold
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "-"
                                }
                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Gold"
                                    color: Theme.secondaryHighlightColor
                                }
                            }

                        }
                    }
                }

                Row {
                    id: stats
                    anchors.horizontalCenter: parent.horizontalCenter

                    property int itemSize: parent.width / 3 - Theme.horizontalPageMargin
                    property int hp: 0
                    property int hpMax: 1
                    property int mp: 0
                    property int mpMax: 1
                    property int xp: 0
                    property int xpNext: 1

                    Stat {
                        width: parent.itemSize
                        value: stats.hp
                        maximum: stats.hpMax
                        label: "Health"
                        barColor: "#da5353"
                    }

                    Stat {
                        width: parent.itemSize
                        value: stats.xp
                        maximum: stats.xpNext
                        label: "Experience"
                        barColor: "#ffcc35"
                    }

                    Stat {
                        id: mana
                        width: parent.itemSize
                        value: stats.mp
                        maximum: stats.mpNext
                        label: "Mana"
                        barColor: "#4781e7"
                    }

                }

            }

            SectionHeader {
                text: "Tasks"
            }

            // TODO regrouper

            BackgroundItem {
                width: parent.width
                contentHeight: Theme.itemSizeSmall
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-m-favorite"
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Habits"
                    }
                }

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Habits.qml"))
                }
            }

            BackgroundItem {
                width: parent.width
                contentHeight: Theme.itemSizeSmall
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-m-clock"
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Dailies"
                    }
                }

                onClicked: {

                }
            }

            BackgroundItem {
                width: parent.width
                contentHeight: Theme.itemSizeSmall
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-m-certificates"
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "To-Dos"
                    }
                }

                onClicked: {

                }
            }

        }
    }

    function update() {
        profileName.text = Model.getName();
        stats.hpMax = Model.getHpMax();
        stats.hp = Model.getHp();
        mana.visible = Model.getLevel() >= 10;
        stats.mpMax = Model.getMpMax();
        stats.mp = Model.getMp();
        stats.xpNext = Model.getXpNext();
        stats.xp = Model.getXp();
        gold.text = Model.getGold();
        gems.text = Model.getGems();
    }

    Component.onCompleted: {
        profilePicture.source = Qt.resolvedUrl(Model.getProfilePictureUrl())
        update();
        Model.signals.updateStats.connect(update);
    }
}
