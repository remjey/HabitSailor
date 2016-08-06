import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {

    ListView {
        id: list
        anchors.fill: parent

        model: ListModel {}

        header: PageHeader {
            title: "To-Dos"
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItem {

            id: taskItem
            hollowRect: true
            subLabel: model.cltotal === 0
                      ? ""
                      : model.clcompleted + " / " + model.cltotal + " subtasks completed"

            menu: ContextMenu {
                id: contextMenu

                Component {
                    id: subtaskItem
                    TextSwitch {
                        property int taskIndex
                        property string taskId
                        property string subtaskId
                        width: parent.width
                        height: Theme.itemSizeExtraSmall
                        onClicked: {
                            Model.setSubtask(taskId, subtaskId, function (ok, value) {
                                busy = false;
                                enabled = true;
                                if (!ok) checked = !checked; // Reverse change
                                else if (checked === value) {
                                    list.model.setProperty(taskIndex, "clcompleted", list.model.get(taskIndex).clcompleted + (checked ? 1 : -1));
                                } else {
                                    // The server said to us that the new value the value before
                                    // we tried to change, so roll-back!
                                    checked = value;
                                }
                            });
                            enabled = false;
                            busy = true;
                        }
                    }
                }

                MenuItem {
                    text: "Check Task"
                    onClicked: {
                        taskItem.remorse("Check " + model.text, function () {
                            taskItem.enabled = false;
                            taskItem.busy = true;
                            Model.setTask(model.id, true, function (ok) {
                                if (ok) {
                                    list.model.remove(model.index, 1);
                                } else {
                                    taskItem.enabled = true;
                                    taskItem.busy = false;
                                }
                            });
                        })
                    }
                }

                MenuItem {
                    id: checkSubtasksMenu
                    visible: false
                    text: "Update Checklist"
                }

                Column {
                    id: subtaskItemList
                    width: parent.width
                    visible: false

                    SectionHeader {
                        text: "Checklist"
                    }
                }

                Component.onCompleted: {
                    if (model.cltotal > 0) {
                        if (model.cltotal <= 6) {
                            subtaskItemList.visible = true;
                            for (var i in subtasks[model.id]) {
                                var item = subtasks[model.id][i];
                                var citem = subtaskItem.createObject(subtaskItemList);
                                citem.taskIndex = model.index;
                                citem.taskId = model.id;
                                citem.subtaskId = item.id;
                                citem.checked = item.completed;
                                citem.text = item.text;
                            }
                        } else {
                            checkSubtasksMenu.visible = true;
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

    function update() {
        var todos = Model.listTodos();
        subtasks = {}
        list.model.clear();
        for (var i in todos) {
            var task = todos[i];
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            list.model.append(task);
        }
    }

    Component.onCompleted: {
        update();
    }

    SignalConnect {
        signl: Model.signals.updateTasks
        fun: update
    }

}

