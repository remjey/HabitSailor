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
    id: root

    property string taskMode
    property string taskName
    property string taskNotes
    property string taskId
    property var checklist

    // TODO use a normal page with a Repeater for checklist

    SilicaListView {
        id: list
        anchors.fill: parent

        header: Column {
            width: parent.width

            PageHeader {
                title: taskMode == "todos"
                       ? qsTr("To-Do")
                       : qsTr("Daily")
            }

            SectionHeader {
                text: qsTr("Title")
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.highlightColor
                text: taskName
            }

            SectionHeader {
                text: qsTr("Extra Notes")
                visible: notes.visible
            }

            Label {
                id: notes
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                text: taskNotes
                visible: !!taskNotes.trim()
            }

            // TODO maybe add some elements from the task object here like due date etc

            SectionHeader {
                text: qsTr("Checklist")
                visible: model.count > 0
            }
        }

        footer: Item { height: Theme.paddingLarge }

        VerticalScrollDecorator {}

        delegate: ListItem {
            height: textSwitch.height
            TextSwitch {
                id: textSwitch
                width: parent.width
                text: model.text // TODO max number of chars
                checked: model.completed
                onClicked: {
                    Model.setSubtask(taskId, model.id, function (ok, value) {
                        busy = false;
                        enabled = true;
                        if (!ok) checked = !checked; // Reverse change
                        else checked = value;
                    });
                    enabled = false;
                    busy = true;
                }
            }
        }

    }

    ListModel {
        id: model
    }

    Component.onCompleted: {
        checklist.forEach(function (item) {
            model.append(item);
        });
        list.model = model;
    }

}
