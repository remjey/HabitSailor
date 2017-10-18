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

    EmptyListHint {
        visible: list.model.count === 0
        label: mode == "todos"
               ? qsTr("No To-Dos")
               : qsTr("No Dailies")
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: tasksModel

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
            showColor: !model.completed && model.isDue
            crossed: model.completed
            subLabel: model.cltotal === 0
                      ? ""
                      : qsTr("%1 / %2 subtasks completed").arg(model.clcompleted).arg(model.cltotal)

            menu: Component {
                ContextMenu {
                    id: contextMenu

                    MenuItem {
                        text: model.completed ? qsTr("Uncheck Task") : qsTr("Check Task")
                        onClicked: taskItem.checkMe()
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
                        onClicked: taskItem.deleteMe()
                    }

                    Column {
                        id: subtaskListContainer
                        width: parent.width
                        visible: false

                        SectionHeader {
                            text: qsTr("Quick Checklist")
                        }

                        Repeater {
                            id: subtasksList
                            model: ListModel {}
                            delegate: Component {
                                BackgroundItem {
                                    id: stbg
                                    width: parent.width
                                    height: Theme.itemSizeExtraSmall

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
                                            checked: model.checked
                                        }
                                    }

                                    Label {
                                        id: label
                                        anchors.left: sbswitchItem.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - x - Theme.horizontalPageMargin
                                        color: stbg.highlighted ? Theme.highlightColor : Theme.primaryColor
                                        text: model.text
                                        opacity: stbg.enabled ? 1 : 0.4
                                        truncationMode: TruncationMode.Fade
                                    }

                                    onClicked: {
                                        enabled = false;
                                        sbswitch.busy = true;
                                        Model.setSubtask(model.taskId, model.subtaskId, function (ok, value) {
                                            sbswitch.busy = false;
                                            enabled = true;
                                            // Update of the value will get taken care of by signal
                                        });
                                    }

                                    Connections {
                                        target: Signals
                                        onSetSubtask: {
                                            if (subtaskId === model.subtaskId)
                                                sbswitch.checked = checked;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        if (model.cltotal > 0 && model.cltotal <= 5) {
                            subtaskListContainer.visible = true;
                            subtasks[model.id].forEach(function (item) {
                                var subtask = {
                                    taskId: model.id,
                                    subtaskId: item.id,
                                    checked: item.completed,
                                    text: item.text,
                                };
                                subtasksList.model.append(subtask);
                            });
                        }
                    }
                }
            }

            function checkMe() {
                var action = function () {
                    enabled = false;
                    busy = true;
                    Model.setTask(model.id, !model.completed, function (ok) {
                        enabled = true;
                        busy = false;
                        if (ok) {
                            if (mode == "todos") list.model.remove(model.index, 1);
                            else list.model.setProperty(model.index, "completed", !model.completed);
                        }
                    });
                };
                if (mode == "dailies")
                    action();
                else
                    remorseAction(qsTr("Check %1").arg(model.text), action);
            }

            function deleteMe() {
                remorseAction(qsTr("Deleting"), function () {
                    enabled = false;
                    busy = true;
                    Model.deleteTask(model.id, function (ok) {
                        if (!ok) {
                            enabled = true;
                            busy = false;
                        }
                    });
                })
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
        tasksModel.clear();
        tasks.forEach(function (task) {
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            delete task.checklist;
            tasksModel.append(task);
        });
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

