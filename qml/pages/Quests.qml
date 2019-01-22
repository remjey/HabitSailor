import QtQuick 2.0
import Sailfish.Silica 1.0

import "../utils.js" as Utils
import ".."
import "../components"

Page {

    ListModel { id: quests }

    SilicaListView {
        anchors.fill: parent

        VerticalScrollDecorator {}

        header: PageHeader { title: qsTr("Available Quests") }

        footer: Item { height: Theme.paddingLarge }

        delegate: MenuButton {
            imageSource: model.iconSource
            label: model.name
            preventAmbianceAdaptation: true
            allowLabelWrapping: true
            onClicked: pageStack.push(Qt.resolvedUrl("QuestDetails.qml"), { quest: questsData[model.key] })
        }

        model: quests
    }

    property var questsData: ({})

    Component.onCompleted: {
        Model.listQuests().forEach(function (q) {
            questsData[q.key] = q;
            quests.append(Utils.filterObject([ "key", "name", "iconSource" ], q));
        });
    }
}
