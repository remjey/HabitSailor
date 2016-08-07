import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {

    ListView {
        id: list
        anchors.fill: parent

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
                            width: Theme.itemSizeExtraSmall
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
                                if (ok) checked = value;
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
                    visible: model.cltotal > 0 || !!model.notes.trim(); // && !!model.notes.trim()
                    text: "View Details" + (model.cltotal > 0 ? " and Checklist" : "")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("Checklist.qml"),
                                       {
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

    ListModel { id: todosModel }

    function update() {
        var todos = Model.listTodos();
        subtasks = {}
        list.model = null
        todosModel.clear();
        for (var i in todos) {
            var task = todos[i];
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            todosModel.append(task);
        }
        list.model = todosModel
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
            for (var i = 0; i < todosModel.count; i++) {
                var todo = todosModel.get(i);
                if (todo.id !== taskId) continue;
                todosModel.setProperty(i, "clcompleted", todo.clcompleted + (checked ? 1 : -1))
                break;
            }
        }
    }

}

