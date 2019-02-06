import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."

Dialog {

    ListModel {
        id: statsModel
        ListElement { name: qsTr("Strength"); key: "str"; current: 0; total: 0; alloc: 0 }
        ListElement { name: qsTr("Intelligence"); key: "int"; current: 0; total: 0; alloc: 0 }
        ListElement { name: qsTr("Constitution"); key: "con"; current: 0; total: 0; alloc: 0 }
        ListElement { name: qsTr("Perception"); key: "per"; current: 0; total: 0; alloc: 0 }
    }

    property int unallocated: 0
    property int allocated: 0

    canAccept: allocated > 0

    onAccepted: {
        var mainPage = pageStack.find(function (page) { return page.pageName === "Main" });
        mainPage.allocateStatPointsBusy = true;
        var allocs = {};
        for (var i = 0; i < statsModel.count; ++i) {
            var si = statsModel.get(i);
            allocs[si.key] = si.alloc;
        }
        Model.allocateStatPoints(allocs, function () {
            mainPage.allocateStatPointsBusy = false;
        });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            width: parent.width

            DialogHeader {
                title: qsTr("Allocate Stat Points")
            }

            Label {
                width: parent.width
                horizontalAlignment: "AlignHCenter"
                color: Theme.secondaryHighlightColor
                text: qsTr("Available points: %1").arg(unallocated - allocated)
            }

            Item { height: Theme.paddingMedium; width: 1 }

            Repeater {
                model: statsModel
                delegate: ListItem {
                    id: statItem
                    contentHeight: statItemContent.implicitHeight + Theme.paddingMedium

                    Column {
                        id: statItemContent
                        width: parent.width + Theme.horizontalPageMargin * 2
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingMedium / 2

                        Label {
                            color: statItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                            font.pixelSize: Theme.fontSizeLarge
                            text: model.name
                        }

                        Label {
                            color: statItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            text: qsTr("Total: %1").arg(model.total)
                        }

                        Label {
                            color: statItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            text: qsTr("Allocated: %1").arg(model.current)
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: itemStatPlus.left
                        color: statItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        visible: model.alloc > 0
                        text: "+" + model.alloc
                    }

                    Item {
                        id: itemStatPlus
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin

                        width: allocated < unallocated ? itemStatPlusImage.implicitWidth + Theme.paddingMedium : 0
                        height: itemStatPlusImage.height
                        opacity: allocated < unallocated ? 1.0 : 0.0

                        Behavior on width { NumberAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Image {
                            id: itemStatPlusImage
                            anchors.right: parent.right
                            source: "image://theme/icon-m-add" + (parent.highlighted ? "?" + Theme.highlightColor : "")
                        }

                    }

                    onClicked: {
                        if (allocated < unallocated) {
                            statsModel.setProperty(model.index, "alloc", model.alloc + 1);
                            ++allocated;
                        }
                    }
                }
            }

            Item { height: Theme.paddingLarge; width: 1}

            Button {
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                enabled: allocated > 0

                text: qsTr("Reset")
                onClicked: {
                    allocated = 0;
                    for (var i = 0; i < statsModel.count; ++i) {
                        statsModel.setProperty(i, "alloc", 0);
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        unallocated = Model.getUnallocatedStatPoints();
        var cstats = Model.getStats();
        for (var i = 0; i < statsModel.count; ++i) {
            var si = statsModel.get(i);
            statsModel.setProperty(i, "current", cstats[si.key]);
            statsModel.setProperty(i, "total", cstats.total[si.key]);
        }
    }
}
