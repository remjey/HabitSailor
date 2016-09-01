import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Dialog {
    id: root

    property string type: "habit" // can be "daily" and "todo"

    canAccept: taskTitle.text.trim() != ""

    acceptDestination: busyPage

    onAccepted: {
        var task = {
            title: taskTitle.text,
            notes: taskNotes.text,
            up: taskUp.checked,
            down: taskDown.checked,
            difficulty: taskDifficulty.currentIndex,
        };
        Model.createTask(type, task, function (ok) {
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
                title: qsTr("New Habit")
            }

            TextField {
                id: taskTitle
                width: parent.width
                label: qsTr("Title")
                placeholderText: label
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: taskNotes.focus = true
            }

            TextArea {
                id: taskNotes
                width: parent.width
                height: Math.min(implicitHeight, root.height / 3)
                label: qsTr("Extra Notes")
                placeholderText: label
            }

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
                    text: qsTr("Creating Habit") // TODO
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

    Component.onCompleted: {
        taskTitle.focus = true;
    }

}
