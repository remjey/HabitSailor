import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

CoverBackground {

    SignalConnect {
        signl: Model.signals.updateStats
        fun: function () {
            if (state == "INIT") state = "STATS";
            name.text = Model.getName();
            profilePic.source = Qt.resolvedUrl(Model.getProfilePictureUrl());
            health.maximum = Model.getHpMax();
            health.value = Model.getHp();
            exp.maximum = Model.getXpNext();
            exp.value = Model.getXp();
            gp.text = Math.floor(Model.getGold());
            var list = Model.listDailies();
            var completed = 0, active = 0;
            dailiesList.model.clear();
            var c = list.forEach(function (item) {
                if (item.activeToday) active++;
                if (item.completed) completed++;
                if (item.activeToday && !item.completed) dailiesList.model.append(item);
            });
            completedDailies.text = completed + "/" + active;
        }
    }

    states: [
        State {
            name: "INIT"
            PropertyChanges { target: placeHolderImage; visible: true }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: false }
            PropertyChanges { target: dailiesList; visible: false }
        },
        State {
            name: "STATS"
            PropertyChanges { target: placeHolderImage; visible: false }
            PropertyChanges { target: content; visible: true }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: false }
        },
        State {
            name: "DAILIES"
            PropertyChanges { target: placeHolderImage; visible: false }
            PropertyChanges { target: content; visible: false }
            PropertyChanges { target: actionList; enabled: true }
            PropertyChanges { target: dailiesList; visible: true }
        }

    ]

    Component.onCompleted: {
        state = "INIT";
    }

    Image {
        id: placeHolderImage
        anchors.centerIn: parent
        source: Qt.resolvedUrl("../assets/habitica.png")
        opacity: 0.7
    }

    Column {
        id: content
        width: parent.width - Theme.paddingSmall * 2
        y: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingSmall

        Label {
            id: name
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Image.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Image {
            id: profilePic
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.width / 2.4
            width: height
            asynchronous: true
            opacity: 0.7
        }

        Grid {
            id: statsGrid
            x: Theme.paddingMedium
            width: parent.width - x
            columns: 2

            Label {
                id: healthLabel
                text: "HP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Bar {
                id: health;
                width: parent.width - x;
                height: healthLabel.height
                color: "#da5353"
            }

            Label {
                id: expLabel
                text: "XP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Bar {
                id: exp;
                width: parent.width - x;
                height: expLabel.height
                color: "#ffcc35"
            }

            Label {
                text: "GP"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Item {
                height: gp.height;
                width: gp.width + gp.x
                Label {
                    id: gp
                    x: Theme.paddingMedium
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        Row {
            x: Theme.paddingMedium
            spacing: Theme.paddingMedium
            Label {
                text: qsTr("Dailies")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Label {
                id: completedDailies
                color: Theme.primaryColor
                text: ""
                font.pixelSize: Theme.fontSizeSmall
            }
        }

    }

    ListView {
        id: dailiesList
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall

        model: ListModel {}

        delegate: Item {
            width: parent.width
            height: itemLabel.height + Theme.paddingSmall

            Rectangle {
                id: rect
                anchors.verticalCenter: parent.verticalCenter
                height: Theme.paddingMedium
                width: height
                color: model.color
                opacity: 0.7
            }

            Label {
                id: itemLabel
                text: model.text;
                anchors.left: rect.right
                anchors.leftMargin: Theme.paddingMedium
                width: parent.width - x
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: Theme.primaryColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                lineHeight: 0.8
            }
        }
    }

    OpacityRampEffect {
        sourceItem: dailiesList
        direction: OpacityRamp.TopToBottom
        offset: 0.7
        slope: 1 / (1 - offset)
    }

    CoverActionList {
        id: actionList
        CoverAction {
            iconSource: "image://theme/icon-cover-subview"
            onTriggered: {
                if (state == "STATS") state = "DAILIES";
                else state = "STATS";
            }
        }
    }
}


