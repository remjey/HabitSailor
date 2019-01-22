import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import ".."

Page {

    ListModel { id: skills }

    property bool loading: false
    property double mp: 0
    property double mpMax: 0
    property double hp: 0
    property double hpMax: 0

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: qsTr("Skills")
            }

            Row {
                width: parent.width - Theme.paddingMedium * 2
                anchors.horizontalCenter: parent.horizontalCenter

                Stat {
                    width: parent.width / 2

                    label: qsTr("Health")
                    barColor: "#da5353"

                    value: hp
                    maximum: hpMax
                }

                Stat {
                    width: parent.width / 2

                    label: qsTr("Mana")
                    barColor: "#4781e7"

                    value: mp
                    maximum: mpMax
                }
            }

            Column {
                width: parent.width

                Repeater {
                    model: skills

                    delegate: MenuButton {
                        imageSource: model.iconSource
                        label: model.text
                        subLabel: model.notes
                        enabled: model.mana <= mp && !loading
                        preventAmbianceAdaptation: true

                        onClicked: useSkill(model.key, model.text, model.target)
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: loading
        size: BusyIndicatorSize.Large
    }

    function useSkillNow(id, target) {
        loading = true;
        Model.useSkill(id, target, function (ok) {
            loading = false;
        });
    }

    function useSkill(id, name, targetType) {
        if (targetType === "self" || targetType === "party" || targetType === "tasks") {
            useSkillNow(id)
        } else if (targetType === "user") {
            // TODO show users
        } else if (targetType === "task") {
            pageStack.push(Qt.resolvedUrl("SkillsTaskSelection.qml"), { spellId: id, skillName: name })
        }
    }

    function updateStats() {
        mp = Model.getMp();
        mpMax = Model.getMpMax();
        hp = Model.getHp();
        hpMax = Model.getHpMax();
    }

    Component.onCompleted: {
        updateStats();
        Model.listSkills().forEach(function (skill) {
            if (skill.mana) {
                skill.notes += "\n" + qsTr("Costs %1 MP").arg(skill.mana);
            } else {
                skill.mana = 0
            }
            skills.append(skill);
        });
    }

    Connections {
        target: Signals
        onUpdateStats: updateStats();
    }
}
