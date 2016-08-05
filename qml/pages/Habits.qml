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
            title: "Habits"
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        function habitUpdate(index, ok, c) {
            if (ok) {
                model.setProperty(index, "color", c)
            }
        }

        delegate: TaskItem {
            showColor: model.up || model.down

            menu: ContextMenu {
                id: contextMenu
                Row {
                    width: parent.width
                    height: Theme.itemSizeLarge

                    HabitButton {
                        width: model.up ? parent.width / 2 : parent.width
                        imageDown: true
                        visible: model.down
                        onClicked: {
                            Model.habitClick(model.id, "down", list.habitUpdate.bind(list, model.index));
                            hideMenu();
                        }
                    }

                    HabitButton {
                        width: model.down ? parent.width / 2 : parent.width
                        visible: model.up
                        onClicked: {
                            Model.habitClick(model.id, "up", list.habitUpdate.bind(list, model.index));
                            hideMenu();
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: !model.down && !model.up
                        text: "This item has no enabled buttons"
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

    SignalConnect {
        signl: Model.signals.updateTasks
        fun: update
    }

}

