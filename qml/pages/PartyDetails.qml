import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import ".."

Page {
    id: root

    property string pageName: "PartyDetails" // Used for app self-navigation

    property var details: null
    property var members: []
    property bool reloadMembers: true

    property bool amLeader: false
    property bool amQuestLeader: false
    property bool amQuester: false
    property bool haveDeclinedQuest: false
    property bool hasQuest: false
    property bool questActive: false
    property bool questCollect: false
    property bool questBoss: false

    Component.onCompleted: updateData();

    function updateData(cdetails) {
        if (cdetails) details = cdetails;
        reloadMembers = true;
        membersRepeater.model.clear();
        questersRepeater.model.clear();
        questDeclinersRepeater.model.clear();

        pageHeader.title = details.name;
        amLeader = details.leader === Model.getMyId();

        _updateQuestData(details.quest);
    }

    SilicaFlickable {
        id: page
        anchors.fill: parent
        contentHeight: pageContent.implicitHeight + Theme.paddingLarge

        VerticalScrollDecorator {}

        PullDownMenu {
            id: pdMenu
            /* TODO
            MenuItem {
                text: qsTr("Leave party")
            } */

            MenuItem {
                text: qsTr("Invite party to a quest")
                enabled: !pdMenu.busy
                visible: !hasQuest
                onClicked: pageStack.push(Qt.resolvedUrl("Quests.qml"))
            }

            MenuItem {
                text: qsTr("Accept quest")
                enabled: !pdMenu.busy
                visible: hasQuest && !amQuester && !haveDeclinedQuest && !questActive
                onClicked: questActionRemorsePopup.show(qsTr("Accepting quest"), "accept")
            }

            MenuItem {
                text: qsTr("Decline quest")
                enabled: !pdMenu.busy
                visible: hasQuest && !amQuester && !haveDeclinedQuest && !questActive
                onClicked: questActionRemorsePopup.show(qsTr("Declining quest"), "reject")
            }

            MenuItem {
                text: qsTr("Start quest")
                enabled: !pdMenu.busy
                visible: hasQuest && (amLeader || amQuestLeader) && !questActive
                onClicked: questActionRemorsePopup.show(qsTr("Starting quest"), "force-start")
            }

            MenuItem {
                text: qsTr("Cancel quest")
                enabled: !pdMenu.busy
                visible: hasQuest && (amLeader || amQuestLeader) && !questActive
                onClicked: questActionRemorsePopup.show(qsTr("Cancelling quest"), "cancel")
            }

            MenuItem {
                text: qsTr("Leave quest")
                enabled: !pdMenu.busy
                visible: hasQuest && questActive && amQuester && !amQuestLeader
                onClicked: questActionRemorsePopup.show(qsTr("Leaving quest"), "leave")
            }

            MenuItem {
                text: qsTr("Abort quest")
                enabled: !pdMenu.busy
                visible: hasQuest && (amLeader || amQuestLeader) && questActive
                onClicked: questActionRemorsePopup.show(qsTr("Aborting quest"), "abort")
            }

        }

        Column {
            id: pageContent
            width: parent.width

            PageHeader {
                id: pageHeader
                width: parent.width
                title: "Party Details"
            }

            ExpandBox {
                id: questItem
                contentHeight: questItemContent.height

                expanded: hasQuest

                Column {
                    id: questItemContent
                    width: parent.width

                    SectionHeader {
                        text: qsTr("Quest")
                    }

                    ImageWithBusyIndicator {
                        id: questPicture
                        x: Theme.itemSizeLarge
                        width: parent.width - x * 2
                        height: Math.max(Theme.itemSizeLarge, implicitHeight * width / implicitWidth || 0)
                        animateOnLoaded: true
                        fillMode: Image.PreserveAspectCrop
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
                        visible: !questActive

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

                    Item {
                        height: Theme.paddingLarge
                        width: 1
                        visible: questActive
                    }

                    Stat {
                        id: health
                        width: parent.width - Theme.paddingMedium * 2
                        anchors.horizontalCenter: parent.horizontalCenter

                        visible: questActive && questBoss
                        label: qsTr("Health")
                        barColor: "#da5353"
                        secondaryBarColor: "#ffcc35"
                    }

                    Repeater {
                        id: collectRepeater
                        model: ListModel {}

                        visible: questActive && questCollect

                        delegate: KeyValueItem {
                            width: parent.width - Theme.horizontalPageMargin * 2
                            x: Theme.horizontalPageMargin
                            key: model.name
                            value: model.count + " / " + model.max
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Party members who accepted the quest")
                visible: questersRepeater.model.count !== 0
            }

            Repeater {
                id: questersRepeater
                model: ListModel {}
                delegate: memberItemComponent
            }

            SectionHeader {
                text: qsTr("Party members who declined the quest")
                visible: questDeclinersRepeater.model.count !== 0
            }

            Repeater {
                id: questDeclinersRepeater
                model: ListModel {}
                delegate: memberItemComponent
            }

            SectionHeader {
                text: (hasQuest
                       && questersRepeater.model.count + questDeclinersRepeater.model.count != 0
                       ? qsTr("Other party members")
                       : qsTr("Party members"))
                visible: membersRepeater.model.count !== 0 || membersBusy.visible
            }

            Repeater {
                id: membersRepeater
                model: ListModel {}
                delegate: memberItemComponent
            }

            BusyIndicator {
                id: membersBusy
                running: false
                visible: running
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Medium
            }
        }
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (!busy && pageStack.currentPage === root) {
                _updateMembers();
            }
        }
    }

    Connections {
        target: Signals
        onQuestStarted: {
            details.quest = questData;
            _updateQuestData(details.quest);
            _populateMembers();
        }
    }

    Component {
        id: memberItemComponent

        ListItem {
            id: bgItem
            width: parent.width
            contentHeight: Math.max(memberAvatarPanel.height, memberDetails.height)
            opacity: 0

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Component.onCompleted: opacity = 1

            Rectangle {
                opacity: 0.3
                visible: Model.getMyId() === model.id
                anchors.fill: parent
                color: "black"
            }

            PanelBackground {
                id: memberAvatarPanel
                height: Theme.itemSizeLarge
                width: Theme.itemSizeLarge

                Rectangle {
                    height: parent.height
                    width: Theme.paddingSmall
                    opacity: 0.5
                    color: "#" +
                           (model.id === details.leader ? "ff" : "00") +
                           (details.quest && model.id === details.quest.leader ? "ff" : "00") +
                           "00"
                    visible: color != "#000000"
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    running: !memberAvatar.loaded
                    size: BusyIndicatorSize.Small
                }

                Avatar {
                    id: memberAvatar
                    anchors.fill: parent
                    parts: model.parts
                    small: true

                    opacity: loaded ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            Item {
                id: memberDetails
                anchors.left: memberAvatarPanel.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Theme.horizontalPageMargin

                height: memberName.implicitHeight + barRow.implicitHeight

                Label {
                    id: memberName
                    anchors.left: parent.left
                    anchors.right: memberLevel.right
                    anchors.rightMargin: Theme.paddingMedium
                    truncationMode: TruncationMode.Elide
                    text: model.name
                    color: bgItem.highlighted ? Theme.highlightColor : Theme.primaryColor
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

            onClicked: openMenu()

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Send message")
                    onClicked: pageStack.push(
                                   Qt.resolvedUrl("Messages.qml"),
                                   {
                                       updateMessages: true,
                                       title: model.name,
                                       userId: model.id,
                                   });
                }
            }
        }
    }

    RemorsePopup {
        id: questActionRemorsePopup
        function show(msg, action) {
            pdMenu.enabled = false;
            execute(msg, function () {
                pdMenu.busy = true;
                Model.questAction(details.id, action, function (ok, r) {
                    if (ok) {
                        details.quest = r;
                        _updateQuestData();
                        _populateMembers();
                    }
                    pdMenu.busy = false;
                    pdMenu.enabled = true;
                });
            });
        }
        onCanceled: pdMenu.enabled = true;
    }

    function _updateMembers() {
        if (!reloadMembers) return;
        reloadMembers = false;
        membersBusy.running = true;
        Model.getGroupMembers(details.id, details.memberCount, function (ok, o) {
            membersBusy.running = false;
            if (ok) members = o;
            else members = [];
            _populateMembers();
        });
    }

    function _populateMembers() {
        questersRepeater.model.clear();
        questDeclinersRepeater.model.clear();
        membersRepeater.model.clear();
        members.forEach(function (item) {
            (details.quest && typeof(details.quest.members[item.id]) === "boolean"
             ? (details.quest.members[item.id] ? questersRepeater : questDeclinersRepeater)
             : membersRepeater)
            .model.append(item);
        });
    }

    function _updateQuestData() {
        hasQuest = !!details.quest;
        if (!!details.quest) {
            questName.text = details.quest.name;
            questPicture.source = details.quest.iconSource;

            questActive = details.quest.active;
            questCollect = questActive && details.quest.type === "collect";
            questBoss = questActive && details.quest.type === "boss";

            collectRepeater.model.clear();
            if (questActive) {
                if (details.quest.type === "collect") {
                    details.quest.collect.forEach(function (ci) { collectRepeater.model.append(ci); });
                } else if (details.quest.type === "boss") {
                    health.value = details.quest.hp;
                    health.secondaryValue = -details.quest.progress;
                    health.maximum = details.quest.maxHp;
                }
            }

            amQuestLeader = details.quest.leader === Model.getMyId();
            amQuester = details.quest.members[Model.getMyId()] === true;
            haveDeclinedQuest = details.quest.members[Model.getMyId()] === false;
        } else {
            amQuestLeader = false;
            amQuester = false;
            haveDeclinedQuest = false;
        }
    }
}
