import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// One chip per Wi-Fi adapter, so each can be listed, connected and disconnected on its own.
RowLayout {
    id: root

    visible: Nmcli.wirelessInterfaces.length > 1
    spacing: Tokens.spacing.small

    Repeater {
        model: Nmcli.wirelessInterfaces

        StyledRect {
            id: chip

            required property var modelData
            readonly property bool selected: modelData.device === Nmcli.wifiDevice
            readonly property bool connected: Nmcli.isConnectedState(modelData.state)

            Layout.fillWidth: true
            implicitHeight: chipLayout.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

            StateLayer {
                color: chip.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                onClicked: Nmcli.selectDevice(chip.modelData.device)
            }

            RowLayout {
                id: chipLayout

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.normal * 2
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: chip.connected ? "wifi" : "wifi_off"
                    color: chip.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: chip.connected && chip.modelData.connection ? `${chip.modelData.device} · ${chip.modelData.connection}` : chip.modelData.device
                    color: chip.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }
        }
    }
}
