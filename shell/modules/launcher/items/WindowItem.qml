import QtQuick
import Quickshell.Widgets
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

        IconImage {
            id: icon

            asynchronous: true
            source: root.modelData?.icon ?? ""
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: workspace.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitHeight: title.implicitHeight + appClass.implicitHeight

            StyledText {
                id: title

                width: parent.width
                text: root.modelData?.title ?? ""
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                id: appClass

                anchors.top: title.bottom
                width: parent.width
                text: root.modelData?.appClass ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        // Which workspace the window is on.
        StyledRect {
            id: workspace

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            color: Colours.palette.m3secondaryContainer
            radius: Tokens.rounding.full
            implicitWidth: Math.max(implicitHeight, label.implicitWidth + Tokens.padding.large)
            implicitHeight: label.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: label

                anchors.centerIn: parent
                text: root.modelData?.special ? `★ ${root.modelData?.workspace}` : (root.modelData?.workspace ?? "")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSecondaryContainer
            }
        }
    }
}
