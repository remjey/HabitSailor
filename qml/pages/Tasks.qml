import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {

    property string mode: "todos" // either "todos" or "dailies"

    ListView {
        id: list
        anchors.fill: parent

        header: PageHeader {
            title: mode == "todos" ? "To-Dos" : "Dailies"
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItem {

            id: taskItem
            hollowRect: !model.completed
            showColor: !model.completed
            crossed: model.completed
            subLabel: model.cltotal === 0
                      ? ""
                      : model.clcompleted + " / " + model.cltotal + " subtasks completed"

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

                        SignalConnect {
                            signl: Model.signals.setSubtask
                            fun: function (taskId, subtaskId, checked) {
                                if (subtaskId === sbbg.subtaskId)
                                    sbswitch.checked = checked;
                            }
                        }
                    }
                }

                MenuItem {
                    text: model.completed ? "Uncheck Task" : "Check Task"
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
                            taskItem.remorse("Check " + model.text, action);
                    }
                }

                MenuItem {
                    visible: model.cltotal > 0 || !!model.notes.trim(); // && !!model.notes.trim()
                    text: "View Details" + (model.cltotal > 0 ? " and Checklist" : "")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("Checklist.qml"),
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

                Column {
                    id: subtaskItemList
                    width: parent.width
                    visible: false

                    SectionHeader {
                        text: "Quick Checklist"
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
        for (var i in tasks) {
            var task = tasks[i];
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            tasksModel.append(task);
        }
        list.model = tasksModel
    }

    Component.onCompleted: {
        update();
    }

    SignalConnect {
        signl: Model.signals.updateTasks
        fun: update
    }

    SignalConnect {
        signl: Model.signals.setSubtask
        fun: function (taskId, subtaskId, checked) {
            for (var i = 0; i < tasksModel.count; i++) {
                var task = tasksModel.get(i);
                if (task.id !== taskId) continue;
                tasksModel.setProperty(i, "clcompleted", task.clcompleted + (checked ? 1 : -1))
                break;
            }
        }
    }

}

