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
import "../model.js" as Model

CoverBackground {

    Connections {
        target: Model.signals

        onLogout: {
            state = "INIT";
        }

        onUpdateStats: {
            if (state == "INIT") state = "STATS";
            name.text = Model.getName();
            profilePic.source = Qt.resolvedUrl(Model.getProfilePictureUrl());
            health.maximum = Model.getHpMax();
            health.value = Model.getHp();
            exp.maximum = Model.getXpNext();
            exp.value = Model.getXp();
            gp.text = Math.floor(Model.getGold());
            var list = Model.listDailies();
            var completed = 0, active = 0;
            dailiesList.model.clear();
            var c = list.forEach(function (item) {
                if (item.activeToday) {
                    active++;
                    if (item.completed) completed++;
                    else dailiesList.model.append(item);
                }
            });
            if (Model.isSleeping()) {
                sleeping.visible = true;
                dailiesRow.visible = false;
            } else {
                sleeping.visible = false;
                dailiesRow.visible = true;
                completedDailies.text = completed + "/" + active;
            }
        }
    }

    states: [
        State {
            name: "INIT"
            PropertyChanges { target: placeHolder; visible: true }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: false }
            PropertyChanges { target: dailiesList; visible: false }
        },
        State {
            name: "STATS"
            PropertyChanges { target: placeHolder; visible: false }
            PropertyChanges { target: content; visible: true }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: false }
        },
        State {
            name: "DAILIES"
            PropertyChanges { target: placeHolder; visible: false }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: true }
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
        spacing: Theme.paddingSmall

        Label {
            id: name
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Image.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Image {
            id: profilePic
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.width / 2.4
            width: height
            asynchronous: true
            opacity: 0.7
        }

        Grid {
            id: statsGrid
            x: Theme.paddingMedium
            width: parent.width - x
            columns: 2

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
            Item {
                height: gp.height;
                width: gp.width + gp.x
                Label {
                    id: gp
                    x: Theme.paddingMedium
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
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

    ListView {
        // TODO When all dailies are done, display a nice message!

        id: dailiesList
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall

        model: ListModel {}

        delegate: Item {
            width: parent.width
            height: itemLabel.height + Theme.paddingSmall

            Rectangle {
                id: rect
                anchors.verticalCenter: parent.verticalCenter
                height: Theme.paddingMedium
                width: height
                color: model.color
                opacity: 0.7
            }

            Label {
                id: itemLabel
                text: model.text;
                anchors.left: rect.right
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

    CoverActionList {
        id: actionList
        CoverAction {
            iconSource: "image://theme/icon-cover-subview"
            onTriggered: {
                if (state == "STATS") state = "DAILIES";
                else state = "STATS";
            }
        }
    }
}


