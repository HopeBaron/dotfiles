import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.pinned ? "push_pin" : root.modelData?.image ? "image" : "content_paste"
            color: root.modelData?.pinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fill: root.modelData?.pinned ? 1 : 0
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        StyledText {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: pin.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.image ? qsTr("Image (%1)").arg(root.modelData.text) : (root.modelData?.text ?? "")
            font: Tokens.font.body.medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Pin or unpin this clip.
        MaterialIcon {
            id: pin

            anchors.right: remove.visible ? remove.left : parent.right
            anchors.rightMargin: remove.visible ? Tokens.spacing.medium : 0
            anchors.verticalCenter: parent.verticalCenter
            text: "push_pin"
            fill: root.modelData?.pinned ? 1 : 0
            color: root.modelData?.pinned || pinArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outline

            MouseArea {
                id: pinArea

                anchors.fill: parent
                anchors.margins: -Tokens.padding.small
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modelData?.togglePin()
            }
        }

        // Delete this entry from the history (pinned clips are unpinned instead).
        MaterialIcon {
            id: remove

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !(root.modelData?.pinned ?? false)
            text: "delete"
            color: removeArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3outline

            MouseArea {
                id: removeArea

                anchors.fill: parent
                anchors.margins: -Tokens.padding.small
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modelData?.remove()
            }
        }
    }
}
