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

    EmptyListHint {
        visible: list.model.count === 0
        label: qsTr("No custom rewards")
    }

    SilicaListView {
        id: list
        anchors.fill: parent

        model: ListModel { }

        PullDownMenu {
            MenuItem {
                text: qsTr("New Reward")
                onClicked: {
                    pageStack.push("TaskEdit.qml", { taskType: "reward" });
                }
            }
        }

        header: Column {
            width: parent.width
            PageHeader {
                title: qsTr("Custom Rewards")
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("You currently have %1 Gold").arg(Math.floor(Model.getGold()))
            }
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItem {
            id: taskItem
            reward: true
            subLabel: qsTr("Costs %1 Gold").arg(model.value)

            function clickMe() {
                taskItem.enabled = false;
                taskItem.busy = true;
                Model.customRewardClick(model.id, function (ok) {
                    taskItem.enabled = true;
                    taskItem.busy = false;
                });
            }

            function deleteMe() {
                taskItem.remorseAction(qsTr("Deleting"), function () {
                    taskItem.enabled = false;
                    taskItem.busy = true;
                    Model.deleteTask(model.id, function (ok) {
                        if (!ok) {
                            taskItem.enabled = true;
                            taskItem.busy = false;
                        }
                    });
                });
            }

            menu: Component {
                ContextMenu {
                    id: contextMenu

                    MenuItem {
                        text: qsTr("Buy")
                        onClicked: taskItem.clickMe();
                    }

                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: {
                            pageStack.push("TaskEdit.qml",
                                           {
                                               mode: "edit",
                                               taskType: "reward",
                                               taskId: model.id,
                                           });
                        }
                    }

                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: taskItem.deleteMe();
                    }
                }
            }

            onClicked: { showMenu(); }
        }
    }

    function update() {
        list.model.clear();
        Model.listRewards().forEach(function (reward) {
            list.model.append(reward);
        });
    }

    Component.onCompleted: {
        update();
    }

    Connections {
        target: Signals
        onUpdateTasks: update()
    }

}

