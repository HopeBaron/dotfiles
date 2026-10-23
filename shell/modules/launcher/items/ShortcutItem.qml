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
            text: root.modelData?.icon ?? ""
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: keys.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                width: parent.width
                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: root.modelData?.desc ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        StyledRect {
            id: keys

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            color: Colours.palette.m3surfaceContainerHighest
            radius: Tokens.rounding.small
            implicitWidth: keysText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: keysText.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: keysText

                anchors.centerIn: parent
                text: root.modelData?.keys ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3primary
            }
        }
    }
}
