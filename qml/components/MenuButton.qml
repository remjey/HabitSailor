/*
  Copyright 2016 Jérémy Farnaud

  This file is part of HabitSailor.

  HabitSailor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  HabitSailor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Foobar.  If not, see <http://www.gnu.org/licenses/>
*/

import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    width: parent.width
    height: (hidden
             ? 0
             : (root.subLabel
                ? (subLabelItem.y + subLabelItem.height + Theme.paddingMedium)
                : Theme.itemSizeSmall))

    visible: height != 0

    Behavior on height {
        NumberAnimation { duration: 200 }
    }

    opacity: enabled ? 1 : 0.4

    property bool hidden: false
    property url imageSource
    property string label
    property string subLabel
    property bool badge: false

    property bool themeImageSource: imageSource.toString().substring(0, 8) === "image://"

    Item {
        id: box
        anchors.fill: parent

        Image {
            id: imageItem
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: (Theme.itemSizeSmall - height) / 2
            anchors.leftMargin: Theme.horizontalPageMargin
            source: root.imageSource + (themeImageSource && root.highlighted ? "?" + Theme.highlightColor : "")
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
        }

        BusyIndicator {
            anchors.centerIn: imageItem
            running: imageItem.status == Image.Loading
            size: BusyIndicatorSize.Small
        }

        ColorOverlay {
            anchors.fill: imageItem
            source: imageItem
            visible: Theme.colorScheme && !themeImageSource
            color: root.highlighted ? Theme.highlightColor : "#ff000000"
        }

        Label {
            id: labelItem
            anchors.left: imageItem.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPageMargin
            anchors.verticalCenter: imageItem.verticalCenter
            text: root.label
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            id: subLabelItem
            anchors.left: labelItem.left
            anchors.top: labelItem.bottom
            anchors.right: labelItem.right
            text: root.subLabel
            visible: root.subLabel
            height: root.subLabel ? undefined : 0
            color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

    }

    GlassItem {
        id: unreadMessagesGlassItem
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: Theme.itemSizeExtraSmall
        height: Theme.itemSizeExtraSmall
        radius: 1.0
        opacity: badge ? 1.0 : 0.0
        visible: opacity != 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
    }

    function remorse(message, cb) {
        remorseItem.execute(box, message, cb)
    }

    RemorseItem {
        id: remorseItem
    }
}

