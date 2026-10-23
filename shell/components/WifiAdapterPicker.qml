import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Dropdown of Wi-Fi adapters, so each can be listed, connected and disconnected on its own.
StyledRect {
    id: root

    function label(iface: var): string {
        return Nmcli.isConnectedState(iface.state) && iface.connection ? `${iface.device} · ${iface.connection}` : iface.device;
    }

    readonly property var current: Nmcli.wirelessInterfaces.find(i => i.device === Nmcli.wifiDevice) ?? null

    visible: Nmcli.wirelessInterfaces.length > 1
    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3secondaryContainer

    StateLayer {
        color: Colours.palette.m3onSecondaryContainer
        onClicked: menu.expanded = !menu.expanded
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.current && Nmcli.isConnectedState(root.current.state) ? "wifi" : "wifi_off"
            color: Colours.palette.m3onSecondaryContainer
            fill: 1
        }

        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.current ? root.label(root.current) : Nmcli.wifiDevice
            color: Colours.palette.m3onSecondaryContainer
        }

        MaterialIcon {
            text: "expand_more"
            color: Colours.palette.m3onSecondaryContainer
            rotation: menu.expanded ? 180 : 0

            Behavior on rotation {
                Anim {}
            }
        }
    }

    Menu {
        id: menu

        attachTo: root
        attachSideX: Menu.Left
        thisSideX: Menu.Left
        marginY: Tokens.spacing.small
        items: adapters.instances
        active: items.find(i => i.value === Nmcli.wifiDevice) ?? null
        onItemSelected: item => Nmcli.selectDevice(item.value)
    }

    Variants {
        id: adapters

        model: Nmcli.wirelessInterfaces

        MenuItem {
            required property var modelData

            text: root.label(modelData)
            icon: Nmcli.isConnectedState(modelData.state) ? "wifi" : "wifi_off"
            value: modelData.device
        }
    }
}
