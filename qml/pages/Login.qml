import QtQuick 2.0
import Sailfish.Silica 1.0
import "../model.js" as Model

Dialog {
    id: loginPage

    acceptDestination: connectPage

    onAccepted: {
        acceptDestinationInstance.setStatus(qsTr("Connecting"), true);
        if (useHabitica.checked) customHabitRpgUrl.text = ""
        Model.login(customHabitRpgUrl.text,
                    login.text,
                    password.text,
                    function () {
                        acceptDestinationInstance.setStatus(qsTr("Loading Profile"), true);
                        Model.update(function (ok) {
                            if (ok) {
                                pageStack.replaceAbove(null, Qt.resolvedUrl("Main.qml"));
                            } else {
                                acceptDestinationInstance.setStatus(qsTr("Impossible to retrieve profile data although the login and password are correct!"), false)
                            }
                        });
                    },
                    function (msg) {
                        acceptDestinationInstance.setStatus(msg, false)
                    });
    }

    canAccept: true // TODO conditions

    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width


            DialogHeader {
                dialog: loginPage
                acceptText: qsTr("Login")
                title: "HabitSailor"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.WordWrap
                color: Theme.highlightColor
                text: qsTr("Welcome to HabitSailor, an unofficial client for Habitica! Have fun making habits and get tasks done while collecting items and pets!")
            }

            SectionHeader {
                text: qsTr("Login")
            }

            TextSwitch {
                id: useHabitica
                text: qsTr("Use the Habitica.com server")
                description: qsTr("Uncheck only if you want to use a custom Habitica server")
                checked: true
            }

            TextField {
                id: customHabitRpgUrl
                visible: !useHabitica.checked
                width: parent.width
                label: qsTr("URL of the custom Habitica server")
                placeholderText: label
                inputMethodHints: Qt.ImhUrlCharactersOnly
                // TODO validator
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: login.focus = true
            }

            TextField {
                id: login
                width: parent.width
                label: qsTr("Username or email address")
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: password.focus = true
            }

            PasswordField {
                id: password
                width: parent.width
                label: qsTr("Password")
                placeholderText: label
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: loginPage.accept()
            }

        }
    }

    Component {
        // TODO prevent going back?
        id: connectPage
        Page {
            forwardNavigation: false
            function setStatus(text, working) {
                connectStatus.text = text
                connectBusy.running = working;
                connectBusy.visible = working;
                backNavigation = !working;
            }
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                width: parent.width

                Label {
                    id: connectStatus
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Connecting")
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    id: connectBusy
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

}

