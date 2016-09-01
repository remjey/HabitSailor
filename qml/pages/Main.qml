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
                text: qsTr("Log out")
                onClicked: {
                    globalRemorse.execute(qsTr("Logging out"), function () {
                        Model.logout();
                        pageStack.replaceAbove(null, Qt.resolvedUrl("Login.qml"));
                    });
                }
            }
            MenuItem {
                id: sleepMenuItem
                property string remorseText: ""
                text: ""
                onClicked: {
                    globalRemorse.execute(remorseText, function () {
                        sleepMenuItem.enabled = false;
                        menu.busy = true;
                        Model.toggleSleep(function () {
                            sleepMenuItem.enabled = true;
                            menu.busy = false;
                        });
                    });
                }
            }
            MenuItem {
                id: refreshMenuItem
                text: qsTr("Refresh")
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
                text: qsTr("Profile")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    spacing: Theme.paddingMedium

                    PanelBackground {
                        width: Math.min(root.width / 3.2, Theme.itemSizeExtraLarge * 3)
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
                        spacing: Theme.paddingMedium

                        Column {
                            width: parent.width

                            Label {
                                id: profileName
                                width: parent.width

                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                id: sleeping
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("Resting in the Inn", "status")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.secondaryHighlightColor
                            }
                        }

                        Row {
                            width: parent.width

                            Stat {
                                id: gems
                                width: parent.width / 3
                                label: qsTr("Gems")
                            }

                            Stat {
                                id: gold
                                width: parent.width / 3
                                label: qsTr("Gold")
                            }

                            Stat {
                                id: level
                                width: parent.width / 3
                                label: qsTr("Level")
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
                        label: qsTr("Health")
                        barColor: "#da5353"
                    }

                    Stat {
                        id: exp
                        width: parent.itemSize
                        label: qsTr("Experience")
                        barColor: "#ffcc35"
                    }

                    Stat {
                        id: mana
                        width: parent.itemSize
                        label: qsTr("Mana")
                        barColor: "#4781e7"
                    }

                }

            }

            SectionHeader {
                text: qsTr("Tasks")
            }

            MenuButton {
                visible: health.value == 0
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-health"
                label: qsTr("Refill your health")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Revive.qml"));
                }
            }

            MenuButton {
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-favorite"
                label: qsTr("Habits")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Habits.qml"));
                }
            }

            MenuButton {
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-clock"
                label: qsTr("Dailies")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Tasks.qml"), { mode: "dailies" });
                }
            }

            MenuButton {
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-acknowledge"
                label: qsTr("To-Dos")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Tasks.qml"), { mode: "todos" });
                }
            }

            SectionHeader {
                text: qsTr("Rewards")
            }

            MenuButton {
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-health"
                label: qsTr("Health Potion")
                subLabel: qsTr("Costs %1 Gold").arg(25)
                onClicked: {
                    remorse(qsTr("Buying Health Potion"), function () {
                        Model.buyHealthPotion()
                    });
                }
            }
        }
    }

    function update() {
        profileName.text = Model.getName();

        sleeping.visible = Model.isSleeping();
        sleepMenuItem.text = Model.isSleeping() ? qsTr("Check Out of Inn") : qsTr("Rest in the Inn")
        sleepMenuItem.remorseText = Model.isSleeping() ? qsTr("Checking out of inn") : qsTr("Resting in the inn")

        gold.value = Model.getGold();
        gems.value = Model.getGems();
        level.value = Model.getLevel();

        health.value = Model.getHp();
        health.maximum = Model.getHpMax();
        mana.visible = Model.getLevel() >= 10;
        mana.maximum = Model.getMpMax();
        mana.value = Model.getMp();
        exp.maximum = Model.getXpNext();
        exp.value = Model.getXp();
    }

    Component.onCompleted: {
        profilePicture.source = Qt.resolvedUrl(Model.getProfilePictureUrl())
        update();
    }

    Connections {
        target: Model.signals
        onUpdateStats: update();
    }
}
