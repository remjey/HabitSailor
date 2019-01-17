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

CoverBackground {

    Connections {
        target: Signals

        onLogout: {
            state = "INIT";
        }

        onUpdateStats: {
            if (state == "INIT") state = "STATS";
            name.text = Model.getName();
            health.maximum = Model.getHpMax();
            health.value = Model.getHp();
            exp.maximum = Model.getXpNext();
            exp.value = Model.getXp();
            gp.text = Math.floor(Model.getGold());
            if (Model.isSleeping()) {
                sleeping.visible = true;
                dailiesRow.visible = false;
            } else {
                sleeping.visible = false;
                dailiesRow.visible = true;
            }
        }

        onSetTask: updateTasksList();
        onUpdateTasks: updateTasksList();

        onAvatarPainted: {
            avatarPicture.imageData = imageData;
            avatarPicture.requestPaint();
        }

        onUpdateNewMessages: {
            newMessagesIndicator.visible =
                    Model.hasNewMessages() || Model.hasNewPartyMessages();
        }
    }

    function updateTasksList() {
        var completed = 0, active = 0;
        var list = Model.listDailies();
        dailiesList.model.clear();
        list.forEach(function (item) {
            if (item.isDue) {
                active++;
                if (item.completed) completed++;
                else dailiesList.model.append(item);
            }
        });
        completedDailies.text = completed + "/" + active;

        list = Model.listTodos();
        todosList.model.clear();
        list.forEach(function (item) {
            todosList.model.append(item);
        });
    }

    // I think I didn’t understand how states should be used
    states: [
        State {
            name: "INIT"
            PropertyChanges { target: placeHolder; visible: true }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: false }
            PropertyChanges { target: dailiesList; visible: false }
            PropertyChanges { target: todosList; visible: false }
            PropertyChanges { target: backgroundDailyIcon; visible: false }
            PropertyChanges { target: backgroundTodoIcon; visible: false }
        },
        State {
            name: "STATS"
            PropertyChanges { target: placeHolder; visible: false }
            PropertyChanges { target: content; visible: true }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: false }
            PropertyChanges { target: todosList; visible: false }
            PropertyChanges { target: backgroundDailyIcon; visible: false }
            PropertyChanges { target: backgroundTodoIcon; visible: false }
        },
        State {
            name: "DAILIES"
            PropertyChanges { target: placeHolder; visible: false }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: true }
            PropertyChanges { target: todosList; visible: false }
            PropertyChanges { target: backgroundDailyIcon; visible: true }
            PropertyChanges { target: backgroundTodoIcon; visible: false }
        },
        State {
            name: "TODOS"
            PropertyChanges { target: placeHolder; visible: false }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: false }
            PropertyChanges { target: todosList; visible: true }
            PropertyChanges { target: backgroundDailyIcon; visible: false }
            PropertyChanges { target: backgroundTodoIcon; visible: true }
        }
    ]

    Component.onCompleted: {
        state = "INIT";
    }

    Column {
        id: placeHolder
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingSmall

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("../assets/habitica.png")
            opacity: 0.7
        }

        Label {
            width: parent.width - Theme.paddingSmall * 2
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Not Connected")
            color: Theme.secondaryColor
        }

    }

    Column {
        id: content
        width: parent.width - Theme.paddingSmall * 2
        y: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingSmall / 2

        Label {
            id: name
            width: parent.width

            color: Theme.primaryColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
            maximumLineCount: 1
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter;
            width: implicitWidth

            Canvas {
                id: avatarPicture
                width: content.width / 2.4
                height: width
                opacity: 0.8

                property var imageData;

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (imageData)
                        ctx.drawImage(imageData, 0, 0, width, height);
                }
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                id: newMessagesIndicator
                source: "image://theme/icon-m-chat"
            }
        }

        Grid {
            id: statsGrid
            x: Theme.paddingMedium
            width: parent.width - Theme.paddingMedium * 2
            columns: 2
            columnSpacing: Theme.paddingMedium

            Label {
                id: healthLabel
                text: "HP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Bar {
                id: health;
                width: parent.width - x;
                height: healthLabel.height
                color: "#da5353"
            }

            Label {
                id: expLabel
                text: "XP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Bar {
                id: exp;
                width: parent.width - x;
                height: expLabel.height
                color: "#ffcc35"
            }

            Label {
                text: "GP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Label {
                id: gp
                x: Theme.paddingMedium
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Row {
            id: dailiesRow
            x: Theme.paddingMedium
            spacing: Theme.paddingMedium
            Label {
                text: qsTr("Dailies")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Label {
                id: completedDailies
                color: Theme.primaryColor
                text: ""
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Label {
            id: sleeping
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Resting")
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }

    }

    Label {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        visible: dailiesList.visible && dailiesList.model.count === 0
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.secondaryColor
        text: qsTr("Congrats!\nAll dailies completed!")
    }

    Image {
        id: backgroundDailyIcon
        source: Qt.resolvedUrl("../assets/icon-m-clock.svg")
        sourceSize.width: parent.width
        sourceSize.height: parent.width
        opacity: 0.3
    }

    Image {
        id: backgroundTodoIcon
        source: Qt.resolvedUrl("../assets/icon-m-todo.svg")
        sourceSize.width: parent.width
        sourceSize.height: parent.width
        opacity: 0.3
    }

    ListView {
        id: dailiesList
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall

        model: ListModel {}

        delegate: Item {
            width: parent.width
            height: dailiesItemLabel.height + Theme.paddingSmall

            Rectangle {
                id: dailiesRect
                anchors.verticalCenter: parent.verticalCenter
                height: Theme.paddingMedium
                width: height
                color: model.color
                opacity: 0.7
            }

            Label {
                id: dailiesItemLabel
                text: model.text;
                anchors.left: dailiesRect.right
                anchors.leftMargin: Theme.paddingMedium
                width: parent.width - x
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: Theme.primaryColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                lineHeight: 0.8
            }
        }
    }

    ListView {
        id: todosList
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall

        model: ListModel {}

        delegate: Item {
            width: parent.width
            height: todosItemLabel.height + Theme.paddingSmall

            Rectangle {
                id: todosRect
                anchors.verticalCenter: parent.verticalCenter
                height: Theme.paddingMedium
                width: height
                color: model.color
                opacity: 0.7
            }

            Rectangle {
                height: parent.height - Theme.paddingSmall / 2
                y: Theme.paddingSmall / 4
                anchors.right: parent.right
                anchors.left: todosRect.right
                anchors.leftMargin: Theme.paddingMedium / 2
                color: "red"
                visible: model.missedDueDate
                radius: Theme.paddingSmall
                opacity: 0.3
            }

            Label {
                id: todosItemLabel
                text: model.text;
                anchors.left: todosRect.right
                anchors.leftMargin: Theme.paddingMedium
                width: parent.width - x
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: Theme.primaryColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                lineHeight: 0.8
            }
        }
    }

    OpacityRampEffect {
        sourceItem: dailiesList
        direction: OpacityRamp.TopToBottom
        offset: 0.7
        slope: 1 / (1 - offset)
    }

    OpacityRampEffect {
        sourceItem: todosList
        direction: OpacityRamp.TopToBottom
        offset: 0.7
        slope: 1 / (1 - offset)
    }

    CoverActionList {
        id: actionList
        CoverAction {
            iconSource: "image://theme/icon-cover-subview"
            onTriggered: {
                if (state == "STATS") state = "DAILIES";
                else if (state == "DAILIES") state = "TODOS";
                else state = "STATS";
            }
        }
        /* TODO
        CoverAction {
            nSource: "image://theme/icon-cover-new"
            onTriggered: Signals.bringToFront("new-task")
        }
        */
    }
}


