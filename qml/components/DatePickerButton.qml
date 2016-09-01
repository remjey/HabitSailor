import QtQuick 2.0
import Sailfish.Silica 1.0

import "../model.js" as Model

ValueButton {
    property var selectedDate: null
    property var defaultDate: null
    property bool canClear: false

    function openDateDialog() {
        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: selectedDate || defaultDate
                     })

        dialog.accepted.connect(function() {
            selectedDate = dialog.date
        })
    }

    value: selectedDate ? Model.formatDate(selectedDate) : qsTr("none")
    width: parent.width
    onClicked: {
        openDateDialog()
    }

    IconButton {
        visible: canClear && selectedDate
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        icon.source: "image://theme/icon-m-clear"

        onClicked: selectedDate = null
    }
}
