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

    property string mode: "todos" // either "todos" or "dailies"

    SilicaListView {
        id: list
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: mode == "todos"
                      ? qsTr("Add New To-Do")
                      : qsTr("Add New Daily")
                onClicked: {
                    pageStack.push("TaskEdit.qml", { taskType: mode == "todos" ? "todo" : "daily" });
                }
            }
        }

        header: PageHeader {
            title: mode == "todos" ? qsTr("To-Dos") : qsTr("Dailies")
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItem {

            id: taskItem
            showColor: !model.completed && model.activeToday
            crossed: model.completed
            subLabel: model.cltotal === 0
                      ? ""
                      : qsTr("%1 / %2 subtasks completed").arg(model.clcompleted).arg(model.cltotal)

            menu: ContextMenu {
                id: contextMenu

                Component {
                    id: subtaskItem
                    BackgroundItem {
                        id: sbbg
                        width: parent.width
                        height: Theme.itemSizeExtraSmall

                        property int taskIndex
                        property string taskId
                        property string subtaskId
                        property string text
                        property bool checked

                        Item {
                            id: sbswitchItem
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: Theme.itemSizeSmall
                            height: parent.height
                            enabled: false

                            Switch {
                                id: sbswitch
                                anchors.fill: parent
                                checked: sbbg.checked
                            }
                        }

                        Label {
                            id: label
                            anchors.left: sbswitchItem.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - Theme.horizontalPageMargin
                            color: sbbg.highlighted ? Theme.highlightColor : Theme.primaryColor
                            text: sbbg.text
                            opacity: sbbg.enabled ? 1 : 0.4
                            truncationMode: TruncationMode.Fade
                        }

                        onClicked: {
                            enabled = false;
                            sbswitch.busy = true;
                            Model.setSubtask(taskId, subtaskId, function (ok, value) {
                                sbswitch.busy = false;
                                enabled = true;
                                // Update of the value will get taken care of by signal
                            });
                        }

                        Connections {
                            target: Signals
                            onSetSubtask: {
                                if (subtaskId === sbbg.subtaskId)
                                    sbswitch.checked = checked;
                            }
                        }
                    }
                }

                MenuItem {
                    text: model.completed ? qsTr("Uncheck Task") : qsTr("Check Task")
                    onClicked: {
                        var action = function () {
                            taskItem.enabled = false;
                            taskItem.busy = true;
                            Model.setTask(model.id, !model.completed, function (ok) {
                                taskItem.enabled = true;
                                taskItem.busy = false;
                                if (ok) {
                                    if (mode == "todos") list.model.remove(model.index, 1);
                                    else list.model.setProperty(model.index, "completed", !model.completed);
                                }
                            });
                        };
                        if (mode == "dailies")
                            action();
                        else
                            taskItem.remorseAction(qsTr("Check %1").arg(model.text), action);
                    }
                }

                MenuItem {
                    visible: model.cltotal > 0 || !!model.notes.trim();
                    text: model.cltotal > 0
                          ? qsTr("View Details and Checklist")
                          : qsTr("View Details");

                    onClicked: {
                        pageStack.push("TaskDetails.qml",
                                       {
                                           taskMode: mode,
                                           taskName: model.text,
                                           taskNotes: model.notes,
                                           taskId: model.id,
                                           taskIndex: model.index,
                                           checklist: subtasks[model.id]
                                       });
                    }
                }

                MenuItem {
                    text: qsTr("Edit")
                    onClicked: {
                        pageStack.push("TaskEdit.qml",
                                       {
                                           mode: "edit",
                                           taskType: (mode == "todos" ? "todo" : "daily"),
                                           taskId: model.id,
                                       });
                    }
                }

                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
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
                }

                Column {
                    id: subtaskItemList
                    width: parent.width
                    visible: false

                    SectionHeader {
                        text: qsTr("Quick Checklist")
                    }
                }

                Component.onCompleted: {
                    if (model.cltotal > 0) {
                        if (model.cltotal <= 5) {
                            subtaskItemList.visible = true;
                            subtasks[model.id].forEach(function (item) {
                                var citem = subtaskItem.createObject(subtaskItemList);
                                citem.taskIndex = model.index;
                                citem.taskId = model.id;
                                citem.subtaskId = item.id;
                                citem.checked = item.completed;
                                citem.text = item.text;
                            });
                        }
                    }
                }
            }

            onClicked: {
                showMenu();
            }
        }
    }

    property var subtasks: ({})

    ListModel { id: tasksModel }

    function update() {
        var tasks = mode == "todos" ? Model.listTodos() : Model.listDailies();
        subtasks = {}
        list.model = null
        tasksModel.clear();
        tasks.forEach(function (task) {
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            tasksModel.append(task);
        });
        list.model = tasksModel
    }

    Component.onCompleted: {
        update();
    }

    Connections {
        target: Signals
        onUpdateTasks: update();
        onSetSubtask: {
            for (var i = 0; i < tasksModel.count; i++) {
                var task = tasksModel.get(i);
                if (task.id !== taskId) continue;
                tasksModel.setProperty(i, "clcompleted", task.clcompleted + (checked ? 1 : -1))
                break;
            }
        }
    }

}

