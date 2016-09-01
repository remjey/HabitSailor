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
                            target: Model.signals
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
                            taskItem.remorse(qsTr("Check %1").arg(model.text), action);
                    }
                }

                MenuItem {
                    visible: model.cltotal > 0 || !!model.notes.trim();
                    text: model.cltotal > 0
                          ? qsTr("View Details and Checklist")
                          : qsTr("View Details");

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("TaskDetails.qml"),
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
                        text: qsTr("Quick Checklist")
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

    Connections {
        target: Model.signals
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

