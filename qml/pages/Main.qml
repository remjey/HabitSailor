/*
  Copyright 2016 Jérémy Farnaud

  This file is part of HabitSailor.

  HabitSailor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  HabitSailor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Foobar.  If not, see <http://www.gnu.org/licenses/>
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {

    property string pageName: "Main"

    property bool allocateStatPointsBusy: false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        PullDownMenu {
            id: menu
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push("About.qml")
            }

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
                    width: parent.width - Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium

                    PanelBackground {
                        width: Math.min(root.width / 3, Theme.itemSizeExtraLarge * 3)
                        height: width

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: profilePicture.opacity != 1.0 || !profilePicture.available;
                        }

                        Avatar {
                            id: profilePicture
                            anchors.fill: parent
                            opacity: loaded ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }

                            parts: Model.getAvatarParts()

                            onPainted: Signals.avatarPainted(context.getImageData(0, 0, width, height));
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

                    property int itemSize: (parent.width - Theme.horizontalPageMargin) / 3
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

            Column {
                id: unallocatedStatPointsReminder
                width: parent.width
                spacing: Theme.paddingMedium
                clip: true
                visible: height != 0

                property int points: 0

                property bool _visible: false;
                height: _visible ? implicitHeight : 0
                opacity: _visible ? 1.0 : 0.0

                Behavior on height { NumberAnimation { duration: 200 } }

                Behavior on opacity { NumberAnimation { duration: 200 } }

                SectionHeader {
                    text: qsTr("Your stats")
                }

                Label {
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    color: Theme.highlightColor
                    text: qsTr("You have unallocated stat points!")
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium

                    Button {
                        width: 2 * (parent.width - parent.spacing) / 3
                        enabled: !allocateStatPointsBusy && !menu.busy
                        text: qsTr("Allocate stat points");
                        onClicked: pageStack.push(Qt.resolvedUrl("AllocateStatPoints.qml"));
                    }

                    Button {
                        width: (parent.width - parent.spacing) / 3
                        enabled: !allocateStatPointsBusy && !menu.busy
                        text: qsTr("Later");
                        onClicked: {
                            Model.hideUnallocatedStatPoints();
                            unallocatedStatPointsReminder._visible = false
                        }
                    }
                }
            }

            Column {
                id: startANewDay
                width: parent.width
                spacing: Theme.paddingMedium
                clip: true
                visible: height != 0

                property bool _visible: false;
                height: _visible ? implicitHeight : 0
                opacity: _visible ? 1.0 : 0.0

                Behavior on height { NumberAnimation { duration: 200 } }

                Behavior on opacity { NumberAnimation { duration: 200 } }

                SectionHeader {
                    text: qsTr("Cron")
                }

                Label {
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    color: Theme.highlightColor
                    text: qsTr("The last cron ran yesterday or earlier. To start a new day, touch the button below. Before doing so, you may still check yesterday’s dailies.")
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    width: parent.width - Theme.horizontalPageMargin * 2
                    enabled: !menu.busy
                    x: Theme.horizontalPageMargin
                    text: qsTr("Start new day");
                    onClicked: {
                        refreshMenuItem.enabled = false;
                        menu.busy = true
                        Model.cron(function () {
                            refreshMenuItem.enabled = true;
                            menu.busy = false;
                        });
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
                imageSource: Qt.resolvedUrl("../assets/icon-m-todo.svg")
                label: qsTr("To-Dos")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Tasks.qml"), { mode: "todos" });
                }
            }

            SectionHeader {
                text: qsTr("Rewards and Skills")
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

            MenuButton {
                id: customRewardsButton
                enabled: !menu.busy
                imageSource: Qt.resolvedUrl("../assets/icon-m-reward.svg")
                label: qsTr("Custom Rewards")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Rewards.qml"));
                }
            }

            MenuButton {
                id: skillsButton
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-wizard"
                label: qsTr("Skills")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Skills.qml"))
                }
            }

            SectionHeader {
                text: qsTr("Social")
            }

            MenuButton {
                id: messagesButton
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-mail"
                label: qsTr("Messages")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Penpals.qml"));
                }
            }

            MenuButton {
                id: partyButton
                enabled: !menu.busy
                imageSource: Qt.resolvedUrl("../assets/icon-m-team.svg")
                label: qsTr("Party")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PartyChat.qml"));
                }
            }

            SectionHeader {
                text: qsTr("Profile")
                visible: allocateStatPointsButton.visible
            }

            MenuButton {
                id: allocateStatPointsButton
                enabled: !menu.busy
                imageSource: "image://theme/icon-m-capslock"
                label: qsTr("Allocate Stat Points")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AllocateStatPoints.qml"));
                }
            }
        }
    }

    function update() {
        profileName.text = Model.getName();

        customRewardsButton.visible = Model.listRewards().length > 0;

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
        partyButton.hidden = !Model.hasParty();
        messagesButton.hidden = !Model.hasInbox();

        skillsButton.visible = Model.listSkills().length > 0;

        startANewDay._visible = Model.getNeedsCron();
        unallocatedStatPointsReminder._visible = Model.getDisplayUnallocatedStatPoints() && Model.getUnallocatedStatPoints();
        allocateStatPointsButton.hidden = !Model.getUnallocatedStatPoints() > 0;

        updateMessageBadges();
    }

    function updateMessageBadges() {
        messagesButton.badge = Model.hasNewMessages();
        partyButton.badge = Model.hasNewPartyMessages();
    }

    Component.onCompleted: {
        update();
    }

    Connections {
        target: Signals
        onUpdateStats: {
            profilePicture.parts = Model.getAvatarParts();
            update();
        }
        onUpdateNewMessages: {
            updateMessageBadges();
        }
    }
}
