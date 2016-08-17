import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {
    id: root

    property string taskMode
    property string taskName
    property string taskNotes
    property string taskId
    property int taskIndex
    property var checklist

    ListView {
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
                color: Theme.secondaryHighlightColor
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
        for (var i in checklist) {
            model.append(checklist[i]);
        }
        list.model = model;
    }

}

