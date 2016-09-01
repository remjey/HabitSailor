import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {

    SilicaListView {
        id: list
        anchors.fill: parent

        model: ListModel {}

        PullDownMenu {
            MenuItem {
                text: qsTr("New Habit")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("TaskEdit.qml", { type: "habit" }));
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

            menu: ContextMenu {
                id: contextMenu

                function clickItem(dir) {
                    taskItem.enabled = false;
                    taskItem.busy = true;
                    Model.habitClick(model.id, dir, function (ok, c) {
                        taskItem.enabled = true;
                        taskItem.busy = false;
                        if (ok)
                            list.model.setProperty(model.index, "color", c)
                    });
                    hideMenu();
                }

                Row {
                    width: parent.width
                    height: Theme.itemSizeLarge

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

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: !model.down && !model.up
                        text: qsTr("This item has no enabled buttons")
                        color: Theme.secondaryHighlightColor
                    }
                }
            }

            onClicked: { showMenu(); }

        }
    }

    function update() {
        var habits = Model.listHabits();
        list.model.clear();
        for (var i in habits) {
            list.model.append(habits[i]);
        }
    }

    Component.onCompleted: {
        update();
    }

    Connections {
        target: Model.signals
        onUpdateTasks: update()
    }

}

