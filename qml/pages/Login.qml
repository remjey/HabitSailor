import QtQuick 2.0
import Sailfish.Silica 1.0
import "../model.js" as Model

Dialog {
    id: loginPage

    acceptDestination: connectPage
    onAccepted: {
        errorLabel.text = ""
        if (useHabitica.checked) customHabitRpgUrl.text = ""
        Model.login(customHabitRpgUrl.text,
                    login.text,
                    password.text,
                    function () {
                        pageStack.completeAnimation();
                        pageStack.currentPage.setStatus("Loading profile");
                        Model.update(function (ok) {
                            if (ok) {
                                pageStack.replaceAbove(null, Qt.resolvedUrl("Main.qml"));
                            } else {
                                pageStack.pop(loginPage);
                                errorLabel.text = "Impossible to retrieve profile data although the login and password are correct";
                                errorLabel.focus = true;
                                errorLabelColorAnim.start();
                            }
                        });
                    },
                    function (msg) {
                        pageStack.completeAnimation();
                        pageStack.pop(loginPage);
                        errorLabel.text = msg;
                        errorLabel.focus = true;
                        errorLabelColorAnim.start();
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
                acceptText: "Login"
                title: "HabitSailor"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.WordWrap
                color: Theme.highlightColor
                text: "Welcome to HabitSailor, an unofficial client for HabitRPG servers like Habitica! Have fun making habits and get tasks done while collecting items and pets!"
            }

            SectionHeader {
                text: "Login"
            }

            TextSwitch {
                id: useHabitica
                text: "Use the Habitica.com server"
                description: "Uncheck only if you want to use a custom HabitRPG server"
                checked: true
            }

            TextField {
                id: customHabitRpgUrl
                visible: !useHabitica.checked
                width: parent.width
                label: "URL of the custom HabitRPG server"
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
                label: "Username or email"
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: password.focus = true
            }

            PasswordField {
                id: password
                width: parent.width
                label: "Password"
                placeholderText: label
                EnterKey.enabled: text.length > 2
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: loginPage.accept()
            }

            Label {
                id: errorLabel
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.WordWrap

                ColorAnimation on color {
                    id: errorLabelColorAnim
                    running: false
                    from: "red"
                    to: Theme.highlightColor
                    duration: 2000
                }
            }
        }
    }

    Component {
        id: connectPage
        Page {
            function setStatus(text) {
                connectStatus.text = text
            }
            Column {
                anchors.centerIn: parent
                spacing: Theme.paddingLarge

                Label {
                    id: connectStatus
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Connecting"
                    color: Theme.highlightColor
                }

                BusyIndicator {
                    anchors.topMargin: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }
            }
        }
    }

}

