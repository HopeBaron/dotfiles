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
            text: root.modelData?.image ? "image" : "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        StyledText {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: remove.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.image ? qsTr("Image (%1)").arg(root.modelData.text) : (root.modelData?.text ?? "")
            font: Tokens.font.body.medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Delete this entry from the history.
        MaterialIcon {
            id: remove

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
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
