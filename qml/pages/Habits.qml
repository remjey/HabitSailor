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

        delegate: ListItem {
            id: listItem
            contentHeight: Math.max(listItemRow.height + 2 * Theme.paddingMedium, Theme.itemSizeSmall)

            function habitUpdate(ok, c) {
                if (ok) {
                    colorIndicator.color = c;
                    model.color = c;
                }
            }

            Row {
                id: listItemRow
                anchors.centerIn: parent
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingLarge

                Rectangle {
                    id: colorIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.itemSizeSmall / 3
                    height: width
                    color: model.color
                    opacity: model.up || model.down ? 0.8 : 0
                }

                Label {
                    id: itemLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.text
                    width: parent.width - x
                    maximumLineCount: 3
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

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
                            Model.habitClick(model.id, "down", habitUpdate);
                            hideMenu();
                        }
                    }

                    HabitButton {
                        width: model.down ? parent.width / 2 : parent.width
                        visible: model.up
                        onClicked: {
                            Model.habitClick(model.id, "up", habitUpdate);
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

            onClicked: {
                showMenu();
            }
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

