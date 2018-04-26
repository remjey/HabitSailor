import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import ".."

Page {
    id: root

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

        pageHeader.title = details.title;
        amLeader = details.leader === Model.getMyId();

        _updateQuestData(details.quest);
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

                visible: hasQuest

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
                }

                Repeater {
                    id: collectRepeater
                    model: ListModel {}

                    visible: questActive && questCollect

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

                Item {
                    height: Theme.paddingLarge
                    width: 1
                    visible: questActive
                }

                Flow {
                    id: questButtonsFlow
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium

                    opacity: enabled ? 1.0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    property int itemWidth: (width - spacing) / 2

                    Button {
                        width: parent.itemWidth
                        text: qsTr("Accept")
                        visible: !amQuester && !haveDeclinedQuest && !questActive
                        onClicked: questActionRemorsePopup.show(qsTr("Accepting quest"), "accept")
                    }

                    Button {
                        width: parent.itemWidth
                        text: qsTr("Decline")
                        visible: !amQuester && !haveDeclinedQuest && !questActive
                        onClicked: questActionRemorsePopup.show(qsTr("Declining quest"), "reject")
                    }

                    Button {
                        width: parent.itemWidth
                        text: qsTr("Start")
                        visible: (amLeader || amQuestLeader) && !questActive
                        onClicked: questActionRemorsePopup.show(qsTr("Starting quest"), "force-start")
                    }

                    Button {
                        width: parent.itemWidth
                        text: qsTr("Cancel")
                        visible: (amLeader || amQuestLeader) && !questActive
                        onClicked: questActionRemorsePopup.show(qsTr("Cancelling quest"), "cancel")
                    }

                    Button {
                        width: parent.itemWidth * 2 + parent.spacing
                        text: qsTr("Leave")
                        visible: questActive && amQuester && !amQuestLeader
                        onClicked: questActionRemorsePopup.show(qsTr("Leaving quest"), "leave")
                    }

                    Button {
                        width: parent.itemWidth * 2 + parent.spacing
                        text: qsTr("Abort")
                        visible: (amLeader || amQuestLeader) && questActive
                        onClicked: questActionRemorsePopup.show(qsTr("Aborting quest"), "abort")
                    }
                }

                SectionHeader {
                    text: qsTr("Quest members")
                    visible: questersRepeater.model.count !== 0
                }

                Repeater {
                    id: questersRepeater
                    model: ListModel {}
                    delegate: memberItemComponent
                }
            }

            SectionHeader {
                text: (questItem.visible && questersRepeater.model.count !== 0
                       ? qsTr("Other party members")
                       : qsTr("Party members"))
            }

            Repeater {
                id: membersRepeater
                model: ListModel {}
                delegate: memberItemComponent
            }

            BusyIndicator {
                id: membersBusy
                running: false
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

    Component {
        id: memberItemComponent

        Item {
            width: parent.width
            height: Math.max(memberAvatar.height, memberDetails.height)

            Rectangle {
                opacity: 0.3
                visible: Model.getMyId() === model.id
                anchors.fill: parent
                color: "black"
            }

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
                anchors.rightMargin: Theme.horizontalPageMargin

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

    RemorsePopup {
        id: questActionRemorsePopup
        function show(msg, action) {
            questButtonsFlow.enabled = false;
            execute(msg, function () {
                Model.questAction(details.id, action, function (ok, r) {
                    if (ok) {
                        details.quest = r;
                        _updateQuestData();
                        _populateMembers();
                    }
                    questButtonsFlow.enabled = true;
                });
            });
        }
        onCanceled: questButtonsFlow.enabled = true
    }

    function _updateMembers() {
        if (!reloadMembers) return;
        reloadMembers = false;
        membersBusy.running = true;
        Model.getGroupMembers(details.id, function (ok, o) {
            membersBusy.running = false;
            if (ok) members = o;
            else members = [];
            _populateMembers();
        });
    }

    function _populateMembers() {
        questersRepeater.model.clear();
        membersRepeater.model.clear();
        members.forEach(function (item) {
            (details.quest && details.quest.members[item.id] ? questersRepeater : membersRepeater)
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
