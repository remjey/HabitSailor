import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent.width
    height: chatTextField.height

    property bool currentlyPosting: false
    property alias placeholderText: chatTextField.placeholderText
    property alias text: chatTextField.text

    signal sendMessage()

    TextArea {
        id: chatTextField
        anchors.left: parent.left
        anchors.right: chatSendButton.left
        height: Math.min(Theme.itemSizeHuge, implicitHeight)

        labelVisible: false
        placeholderText: qsTr("Type your message here")

        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere

        property bool validMessage: text.trim().length > 0

        EnterKey.onClicked: sendMessage();
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
    }

    IconButton {
        id: chatSendButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingSmall
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Theme.paddingSmall
        icon.source: "image://theme/icon-m-message?" + (pressed
          ? Theme.highlightColor
          : Theme.primaryColor)

        enabled: chatTextField.validMessage && !currentlyPosting

        onClicked: sendMessage();
    }
}
