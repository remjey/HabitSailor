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
        label: qsTr("No habits")
    }

    SilicaListView {
        id: list
        anchors.fill: parent

        model: ListModel { }

        PullDownMenu {
            MenuItem {
                text: qsTr("New Habit")
                onClicked: {
                    pageStack.push("TaskEdit.qml", { taskType: "habit" });
                }
            }
        }

        header: PageHeader {
            title: qsTr("Habits")
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItem {
            id: taskItem
            showColor: model.up || model.down

            function clickMe(dir) {
                enabled = false;
                busy = true;
                Model.habitClick(model.id, dir, function (ok, c) {
                    enabled = true;
                    busy = false;
                    if (ok)
                        list.model.setProperty(index, "color", c)
                });
            }

            menu: Component {
                ContextMenu {
                    id: contextMenu

                    function clickItem(dir) {
                        taskItem.clickMe(dir);
                        hideMenu();
                    }

                    Row {
                        width: parent.width
                        height: Theme.itemSizeLarge
                        visible: model.down || model.up

                        HabitButton {
                            width: model.up ? parent.width / 2 : parent.width
                            imageDown: true
                            visible: model.down
                            onClicked: contextMenu.clickItem("down");
                        }

                        HabitButton {
                            width: model.down ? parent.width / 2 : parent.width
                            visible: model.up
                            onClicked: contextMenu.clickItem("up");
                        }
                    }

                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: {
                            pageStack.push("TaskEdit.qml",
                                           {
                                               mode: "edit",
                                               taskType: "habit",
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
                }
            }

            onClicked: { showMenu(); }

        }
    }

    function update() {
        list.model.clear();
        Model.listHabits().forEach(function (habit) {
            list.model.append(habit);
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

