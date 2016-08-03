import QtQuick 2.0
import Sailfish.Silica 1.0
import "../model.js" as Model

Page {
    id: loginPage

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: "HabitSailor"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.WordWrap
                text: "Welcome to HabitSailor, an unofficial client for HabitRPG servers like Habitica! Have fun making habits and get tasks done while collecting items and pets!"
            }

            SectionHeader {
                text: "Login"
            }

            TextSwitch {
                id: useHabitica
                text: "Use the Habitica server"
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
                EnterKey.onClicked: login.focus = true
                // TODO validator
            }

            TextField {
                id: login
                width: parent.width
                label: "Username or email"
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.onClicked: password.focus = true
            }

            PasswordField {
                id: password
                width: parent.width
                label: "Password"
                placeholderText: label
                EnterKey.onClicked: password.focus = false
            }

            Button {
                id: loginButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Login"
                onClicked: {
                    errorLabel.text = ""
                    if (useHabitica.checked) customHabitRpgUrl.text = ""
                    pageStack.push(connectPage);
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

