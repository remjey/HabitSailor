import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."
import "../components"

Page {

    property string spellId
    property string skillName
    property bool loading: false

    ListModel { id: habits }
    ListModel { id: dailies }
    ListModel { id: todos }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: qsTr("Target for %1").arg(skillName)
            }

            enabled: !loading
            opacity: enabled ? 1.0 : 0.4

            Behavior on opacity { NumberAnimation { duration: 200 } }

            ExpandingSectionGroup {
                animateToExpandedSection: false
                ExpandingSection {
                    title: qsTr("Habits")
                    content.sourceComponent: Column {
                        width: parent.width
                        Repeater {
                            model: habits
                            delegate: TaskItem {
                                compact: true
                                onClicked: useSkill(model.id, habits)
                            }
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("Dailies")
                    content.sourceComponent: Column {
                        width: parent.width
                        Repeater {
                            model: dailies
                            delegate: TaskItem {
                                compact: true
                                isDue: model.isDue
                                crossed: model.completed
                                onClicked: useSkill(model.id, dailies)
                            }
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("To-Dos")
                    content.sourceComponent: Column {
                        width: parent.width
                        Repeater {
                            model: todos
                            delegate: TaskItem {
                                compact: true
                                onClicked: useSkill(model.id, todos)
                            }
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: loading
        size: BusyIndicatorSize.Large
    }

    function useSkill(taskId, updateModel) {
        loading = true;
        Model.useSkill(spellId, taskId, function (ok, o) {
            loading = false;
            if (ok && o.task && updateModel) {
                for (var i = 0; i < updateModel.count; ++i) {
                    if (updateModel.get(i).id === taskId) {
                        updateModel.setProperty(i, "color", o.task.color);
                        break;
                    }
                }
            }
        });
    }

    Component.onCompleted: {
        Model.listHabits().forEach(function (item) {
            habits.append(item);
        });
        Model.listDailies().forEach(function (item) {
            dailies.append(item);
        });
        Model.listTodos().forEach(function (item) {
            todos.append(item);
        });
    }

}
