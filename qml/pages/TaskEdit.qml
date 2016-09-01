import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Dialog {
    id: root

    property string taskType: "habit" // can be "daily" and "todo"

    property var _TaskTitle: ({
                                  new_habit: qsTr("New Habit"),
                                  create_habit: qsTr("Creating New Habit"),
                                  new_daily: qsTr("New Daily"),
                                  create_daily: qsTr("Creating New Daily"),
                                  new_todo: qsTr("New To-Do"),
                                  create_todo: qsTr("Creating New To-Do"),
                              })

    property var _RepeatTypes: ["daily", "weekly", "period", "never"]
    property var _WeekDays: [
        { name: qsTr("Mon"), key: "m"  },
        { name: qsTr("Tue"), key: "t"  },
        { name: qsTr("Wed"), key: "w"  },
        { name: qsTr("Thu"), key: "th" },
        { name: qsTr("Fri"), key: "f"  },
        { name: qsTr("Sat"), key: "s"  },
        { name: qsTr("Sun"), key: "su" },
    ]

    canAccept: (taskTitle.text.trim() != ""
                && (taskRepeatType.currentIndex != 2 || taskPeriod.acceptableInput)
                )

    acceptDestination: busyPage

    function makeRepeatMap() {
        var r = {};
        for (var i = 0; i < weekDaysModel.count; i++) {
            var item = weekDaysModel.get(i);
            r[item.key] = item.checked;
        }
        return r;
    }

    onAccepted: {
        var task = {
            title: taskTitle.text,
            notes: taskNotes.text,
            up: taskUp.checked,
            down: taskDown.checked,
            startDate: taskStartDate.selectedDate,
            repeatType: _RepeatTypes[taskRepeatType.currentIndex],
            weekDays: makeRepeatMap(),
            period: parseInt(taskPeriod.text),
            difficulty: taskDifficulty.currentIndex,
        };

        Model.createTask(taskType, task, function (ok) {
            pageStack.completeAnimation();
            if (ok) pageStack.pop(pageStack.previousPage(root));
            else pageStack.pop(root);
        });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            DialogHeader {
                id: dialogHeader
                cancelText: qsTr("Cancel")
                acceptText: qsTr("Create")
                title: _TaskTitle["new_" + taskType]
            }

            TextField {
                id: taskTitle
                width: parent.width
                label: qsTr("Title")
                placeholderText: label
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: taskTitle.focus = false
            }

            TextArea {
                id: taskNotes
                width: parent.width
                height: Math.min(implicitHeight, root.height / 3)
                label: qsTr("Extra Notes")
                placeholderText: label
            }

            Column {
                width: parent.width
                visible: taskType == "habit"

                SectionHeader {
                    text: qsTr("Direction / Actions")
                }

                TextSwitch {
                    id: taskUp
                    width: parent.width
                    checked: true
                    text: qsTr("Up / Plus")
                }

                TextSwitch {
                    id: taskDown
                    width: parent.width
                    checked: true
                    text: qsTr("Down / Minus")
                }
            }

            Column {
                width: parent.width
                visible: taskType == "daily"

                SectionHeader {
                    text: qsTr("Schedule")
                }

                DatePickerButton {
                    id: taskStartDate
                    selectedDate: Model.getLastCronDate()
                    label: qsTr("Start Date")
                }

                ComboBox {
                    id: taskRepeatType
                    width: parent.width
                    label: qsTr("Repeat")
                    currentIndex: 0

                    menu: ContextMenu {
                        onActiveChanged: {
                            if (parent.currentIndex == 2) {
                                taskPeriod.focus = true
                            }
                        }

                        MenuItem { text: qsTr("every day") }
                        MenuItem { text: qsTr("on certain week days") }
                        MenuItem { text: qsTr("periodically") }
                        MenuItem { text: qsTr("never, make this daily optional") }
                    }
                }

                TextField {
                    id: taskPeriod
                    width: parent.width
                    height: taskRepeatType.currentIndex == 2 ? implicitHeight : 0
                    clip: true

                    Behavior on height {
                        PropertyAnimation {
                            duration: 200
                        }
                    }

                    inputMethodHints: Qt.ImhDigitsOnly
                    label: qsTr("Period length in days")
                    placeholderText: label
                    validator: IntValidator { bottom: 1 }

                    EnterKey.onClicked: taskPeriod.focus = false
                    EnterKey.enabled: acceptableInput
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                }

                Row {
                    id: taskWeekDays
                    height: taskRepeatType.currentIndex == 1 ? implicitHeight : 0
                    clip: true
                    x: Theme.horizontalPageMargin

                    Behavior on height {
                        PropertyAnimation {
                            duration: 200
                        }
                    }

                    Repeater {
                        delegate: Item {
                            width: (root.width - Theme.horizontalPageMargin * 2) / 7
                            height: sw.height + lbl.height

                            Switch {
                                id: sw
                                width: parent.width
                                height: parent.width
                                anchors.horizontalCenter: parent.horizontalCenter
                                highlighted: pressed || ma.pressed
                                checked: model.checked

                                onCheckedChanged: weekDaysModel.setProperty(model.index, "checked", checked)
                            }

                            MouseArea {
                                id: ma
                                width: parent.width
                                height: lbl.height
                                anchors.top: sw.bottom

                                Label {
                                    id: lbl
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: model.name
                                    color: ma.pressed || sw.pressed
                                           ? Theme.highlightColor
                                           : Theme.primaryColor
                                }

                                onClicked: sw.checked = !sw.checked;
                            }

                        }
                        model: ListModel {
                            id: weekDaysModel
                            Component.onCompleted: {
                                _WeekDays.forEach(function (day) {
                                    day.checked = true; // TODO use preexisting data
                                    weekDaysModel.append(day)
                                });
                            }
                        }
                    }

                }


            }

            SectionHeader {
                text: qsTr("Advanced Options")
            }

            ComboBox {
                id: taskDifficulty
                width: parent.width
                label: qsTr("Difficulty")
                currentIndex: 1

                menu: ContextMenu {
                    MenuItem { text: qsTr("trivial") }
                    MenuItem { text: qsTr("easy") }
                    MenuItem { text: qsTr("medium") }
                    MenuItem { text: qsTr("hard") }
                }
            }

        }

    }

    Component {
        // TODO prevent going back?
        id: busyPage
        Page {
            function setStatus(text) {
                status.text = text;
            }

            backNavigation: false
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                width: parent.width

                Label {
                    id: status
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: _TaskTitle["create_" + taskType]
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    id: busy
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

    Component.onCompleted: {
        //TODO should we? taskTitle.focus = true;
    }

}
