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

Dialog {
    id: root

    property string mode: "new" // can be "new" or "edit"
    property string taskType: "habit" // can also be "daily" and "todo" and "reward"
    property string taskId: ""

    property var _TaskTitle: ({
                                  new_habit: qsTr("New Habit"),
                                  edit_habit: qsTr("Edit Habit"),
                                  save_habit: qsTr("Saving Habit"),

                                  new_daily: qsTr("New Daily"),
                                  edit_daily: qsTr("Edit Daily"),
                                  save_daily: qsTr("Saving Daily"),

                                  new_todo: qsTr("New To-Do"),
                                  edit_todo: qsTr("Edit To-Do"),
                                  save_todo: qsTr("Saving To-Do"),

                                  new_reward: qsTr("New Reward"),
                                  edit_reward: qsTr("Edit Reward"),
                                  save_reward: qsTr("Saving Reward"),
                              })

    property var _RepeatTypes: ["daily", "weekly", "monthly", "yearly", "never"]
    property var _PeriodUnit:  [qsTr("days"), qsTr("weeks"), qsTr("months"), qsTr("years"), false]
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
                && (taskRepeatType.currentIndex < 2 && taskRepeatType.currentIndex > 4 || taskPeriod.acceptableInput)
                && (taskType != "reward" || taskValue.acceptableInput)
                )

    acceptDestination: busyPage

    function loadTask(task) {
        taskTitle.text = task.title;
        taskNotes.text = task.notes;
        taskValue.text = task.value;
        taskUp.checked = task.up;
        taskDown.checked = task.down;
        taskStartDate.selectedDate = task.startDate;
        taskRepeatType.set(task.repeatType);
        _WeekDays.forEach(function (w, i) {
            weekDaysModel.setProperty(i, "checked", task.weekDays[w.key]);
        })
        taskPeriod.text = task.everyX;
        taskMonthlyType.currentIndex = task.monthlyWeekDay ? 1 : 0;
        taskDifficulty.currentIndex = task.difficulty;
        task.checklist.forEach(function (item, i) {
            checklistModel.insert(i, { subTaskId: item.id, completed: item.completed, text: item.text });
        });
        taskDueDate.selectedDate = task.dueDate;
    }

    function makeRepeatMap() {
        var r = {};
        for (var i = 0; i < weekDaysModel.count; i++) {
            var item = weekDaysModel.get(i);
            r[item.key] = item.checked;
        }
        return r;
    }

    function makeChecklist() {
        var r = [];
        for (var i = 0; i < checklistModel.count; i++) {
            var item = checklistModel.get(i);
            if (item.text.trim() !== "")
                r.push({
                           id: item.subTaskid || undefined,
                           completed: item.completed,
                           text: item.text
                       });
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
            repeatType: taskRepeatType.enumValue,
            monthlyWeekDay: taskMonthlyType.currentIndex == 1,
            weekDays: makeRepeatMap(),
            everyX: parseInt(taskPeriod.text),
            difficulty: taskDifficulty.currentIndex,
            checklist: makeChecklist(),
            dueDate: taskDueDate.selectedDate,
            value: parseInt(taskValue.text),
        };
        if (taskId) task.id = taskId;

        Model.saveTask(taskType, task, function (ok) {
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
                acceptText: mode == "new"
                            ? qsTr("Create")
                            : qsTr("Save")

                title: _TaskTitle[mode + "_" + taskType]
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

            TextField {
                id: taskValue
                width: parent.width
                label: qsTr("Price")
                placeholderText: label
                inputMethodHints: Qt.ImhDigitsOnly
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: taskValue.focus = false
                visible: taskType == "reward"
                validator: IntValidator { bottom: 1 }
            }

            Column {
                width: parent.width
                visible: taskType == "todo"

                SectionHeader {
                    text: qsTr("Schedule")
                }

                DatePickerButton {
                    id: taskDueDate
                    label: qsTr("Due Date")
                    defaultDate: Model.getLastCronDate()
                    canClear: true
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

                    property string enumValue: _RepeatTypes[currentIndex];

                    function set(s) {
                        currentIndex = _RepeatTypes.find(function (o) { return o === s; });
                    }

                    menu: ContextMenu {
                        MenuItem { text: qsTr("every day or few days") }
                        MenuItem { text: qsTr("every week or few weeks") }
                        MenuItem { text: qsTr("every month or few months") }
                        MenuItem { text: qsTr("every year or few years") }
                        MenuItem { text: qsTr("never, make this daily optional") }
                    }
                }

                TextField {
                    id: taskPeriod
                    width: parent.width
                    height: taskRepeatType.enumValue != "never" ? implicitHeight : 0
                    clip: true

                    Behavior on height {
                        PropertyAnimation {
                            duration: 200
                        }
                    }

                    text: "1"
                    inputMethodHints: Qt.ImhDigitsOnly
                    label: qsTr("Period in %1 (0 to disable)").arg(_PeriodUnit[taskRepeatType.currentIndex])
                    placeholderText: label
                    validator: IntValidator { bottom: 0 }

                    EnterKey.onClicked: taskPeriod.focus = false
                    EnterKey.enabled: acceptableInput
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                }

                ComboBox {
                    id: taskMonthlyType
                    width: parent.width
                    label: qsTr("Due")
                    visible: taskRepeatType.enumValue == "monthly"

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("the same day of the month")
                        }
                        MenuItem {
                            text: qsTr("the same weekday of the month")
                        }
                    }
                }

                Row {
                    id: taskWeekDays
                    height: taskRepeatType.enumValue == "weekly" ? implicitHeight : 0
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
                                    day.checked = true;
                                    weekDaysModel.append(day)
                                });
                            }
                        }
                    }
                }
            }

            Column {
                id: checklist
                height: implicitHeight
                width: parent.width
                visible: taskType == "daily" || taskType == "todo"

                Behavior on height {
                    NumberAnimation { duration: 100 }
                }

                move: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 100
                    }
                }

                add: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: 100
                    }
                }

                SectionHeader {
                    text: qsTr("Checklist")
                }

                ListModel {
                    id: checklistModel
                    ListElement { text: ""; completed: false; keep: false; subTaskId: "" }

                    function manageItems() {
                        for (var i = checklistModel.count - 2; i >= 0; i--) {
                            var item = checklistModel.get(i);
                            if (item.text.trim() === "" && !item.keep) {
                                checklistModel.remove(i);
                            }
                        }
                    }
                }

                Repeater {
                    id: checklistRepeater
                    model: checklistModel
                    delegate: Item {
                        id: checklistItem
                        width: checklist.width // used instead of parent.width to remove a warning when the item is removed from its parent
                        height: field.height

                        function takeFocus() { field.focus = true; }

                        TextField {
                            id: field
                            width: parent.width
                            text: model.text

                            onTextChanged: {
                                checklistModel.setProperty(model.index, "text", text.trim());
                                if (text.trim() != "" && model.index === checklistModel.count - 1) {
                                    checklistModel.insert(model.index + 1, { text: "", completed: false, keep: false, subTaskId: "" });
                                } else if (text.trim() == "" && model.index === checklistModel.count - 2) {
                                    checklistModel.remove(model.index + 1);
                                }
                                updateEnterKeyIcon()
                            }
                            onFocusChanged: {
                                checklistModel.setProperty(model.index, "keep", focus);
                                checklistModel.manageItems();
                                if (focus) updateEnterKeyIcon();
                            }

                            placeholderText: model.index === checklistModel.count - 1
                                             ? qsTr("New Checklist Item")
                                             : ""
                            labelVisible: false

                            function updateEnterKeyIcon() {
                                if (model.index === checklistModel.count - 1)
                                    EnterKey.iconSource = "image://theme/icon-m-enter-close";
                                else if (model.index === checklistModel.count - 2)
                                    EnterKey.iconSource = "image://theme/icon-m-enter-next";
                                else if (text.trim() != "")
                                    EnterKey.iconSource = "image://theme/icon-m-add";
                                else
                                    EnterKey.iconSource = "image://theme/icon-m-remove";
                            }

                            EnterKey.onClicked: {
                                if (model.index === checklistModel.count - 1) {
                                    focus = false;
                                } else {
                                    if (text.trim() != "" && model.index < checklistModel.count - 2) {
                                        var pos = model.index;
                                        if (field.cursorPosition > 0) pos++;
                                        checklistModel.insert(pos, { text: "", completed: false, keep: true, subTaskId: "" })
                                    }
                                    checklistRepeater.itemAt(model.index + 1).takeFocus();
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                visible: taskType != "reward"

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
                    text: _TaskTitle["save_" + taskType]
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
        if (mode == "edit") loadTask(Model.getTaskForEdit(taskId));
        if (mode == "new") taskTitle.focus = true;
    }

}
