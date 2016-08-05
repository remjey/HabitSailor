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
            id: menu
            MenuItem {
                text: "Log out"
                onClicked: {
                    globalRemorse.execute("Logging out", function () {
                        Model.logout();
                        pageStack.replaceAbove(null, Qt.resolvedUrl("Login.qml"));
                    });
                }
            }
            MenuItem {
                id: refreshMenuItem
                text: "Refresh"
                onClicked: {
                    refreshMenuItem.enabled = false;
                    menu.busy = true
                    Model.update(function () {
                        refreshMenuItem.enabled = true;
                        menu.busy = false;
                    });
                }
            }
        }

        RemorsePopup { id: globalRemorse }

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

                    PanelBackground {
                        width: Math.min(root.width / 3, Theme.itemSizeExtraLarge * 3)
                        height: width
                        Image {
                            anchors.fill: parent
                            id: profilePicture
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true;
                        }
                    }

                    Column {
                        width: parent.width - profilePicture.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            id: profileName
                            width: parent.width

                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeLarge
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            width: parent.width

                            Stat {
                                id: gems
                                width: parent.width / 3
                                label: "Gems"
                            }

                            Stat {
                                id: gold
                                width: parent.width / 3
                                label: "Gold"
                            }

                            Stat {
                                id: level
                                width: parent.width / 3
                                label: "Level"
                            }

                        }
                    }
                }

                Row {
                    id: stats
                    anchors.horizontalCenter: parent.horizontalCenter

                    property int itemSize: parent.width / 3 - Theme.horizontalPageMargin
                    Stat {
                        id: health
                        width: parent.itemSize
                        label: "Health"
                        barColor: "#da5353"
                    }

                    Stat {
                        id: exp
                        width: parent.itemSize
                        label: "Experience"
                        barColor: "#ffcc35"
                    }

                    Stat {
                        id: mana
                        width: parent.itemSize
                        label: "Mana"
                        barColor: "#4781e7"
                    }

                }

            }

            SectionHeader {
                text: "Tasks"
            }

            MenuButton {
                visible: health.value == 0
                imageSource: "image://theme/icon-m-health"
                label: "Refill your health"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Revive.qml"));
                }
            }

            MenuButton {
                imageSource: "image://theme/icon-m-favorite"
                label: "Habits"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Habits.qml"));
                }
            }

            MenuButton {
                imageSource: "image://theme/icon-m-clock"
                label: "Dailies"
                onClicked: {

                }
            }

            MenuButton {
                imageSource: "image://theme/icon-m-certificates"
                label: "To-Dos"
                onClicked: {

                }
            }

            SectionHeader {
                text: "Rewards"
            }

            MenuButton {
                imageSource: "image://theme/icon-m-health"
                label: "Health Potion"
                subLabel: "Costs 25 Gold"
                onClicked: {
                    remorse("Buying Health Potion", function () {
                        Model.buyHealthPotion()
                    });
                }
            }
        }
    }

    function update() {
        profileName.text = Model.getName();
        health.value = Model.getHp();
        health.maximum = Model.getHpMax();
        mana.visible = Model.getLevel() >= 10;
        mana.maximum = Model.getMpMax();
        mana.value = Model.getMp();
        exp.maximum = Model.getXpNext();
        exp.value = Model.getXp();
        gold.value = Model.getGold();
        gems.value = Model.getGems();
        level.value = Model.getLevel();
    }

    Component.onCompleted: {
        profilePicture.source = Qt.resolvedUrl(Model.getProfilePictureUrl())
        update();
    }

    SignalConnect {
        signl: Model.signals.updateStats
        fun: update
    }
}
