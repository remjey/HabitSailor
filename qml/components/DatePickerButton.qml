import QtQuick 2.0
import Sailfish.Silica 1.0

import "../model.js" as Model

ValueButton {
    property date selectedDate

    function openDateDialog() {
        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: selectedDate
                     })

        dialog.accepted.connect(function() {
            selectedDate = dialog.date
        })
    }

    value: selectedDate ? Model.formatDate(selectedDate) : "Select"
    width: parent.width
    onClicked: openDateDialog()
}
