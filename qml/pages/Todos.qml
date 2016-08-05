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

            hollowRect: true
            subLabel: model.cltotal === 0
                      ? ""
                      : model.clcompleted + " / " + model.cltotal + " sub-tasks completed"

            menu: ContextMenu {
                id: contextMenu

                Component {
                    id: subtaskItem
                    BackgroundItem {
                        id: subtaskItemInstance
                        property bool completed;
                        property string text;
                        width: parent.width
                        height: Theme.itemSizeExtraSmall
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.horizontalPageMargin
                            spacing: Theme.paddingLarge
                            Rectangle {
                                id: rect
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.itemSizeSmall / 3
                                height: width
                                color: completed ? border.color : "transparent"
                                border.color: subtaskItemInstance.highlighted ? Theme.highlightColor : Theme.primaryColor
                                border.width: Theme.paddingSmall
                                opacity: 0.8
                            }
                            Label {
                                width: parent.width - x - Theme.paddingMedium
                                anchors.verticalCenter: parent.verticalCenter
                                text: subtaskItemInstance.text
                                truncationMode: TruncationMode.Fade
                                font.pixelSize: Theme.fontSizeSmall
                                color: subtaskItemInstance.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                        }
                    }
                }

                MenuItem {
                    text: "Check Task"
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
                                citem.completed = item.completed;
                                citem.text = item.text;
                            }
                        } else {
                            checkSubtasksMenu.visible = true;
                        }
                    }
                }
            }

            onClicked: { showMenu(); }
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

