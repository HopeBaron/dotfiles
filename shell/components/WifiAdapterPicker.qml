import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Dropdown of Wi-Fi adapters, so each can be listed, connected and disconnected on its own.
SplitButton {
    id: root

    function label(iface: var): string {
        return Nmcli.isConnectedState(iface.state) && iface.connection ? `${iface.device} · ${iface.connection}` : iface.device;
    }

    visible: Nmcli.wirelessInterfaces.length > 1
    type: SplitButton.Tonal
    fallbackIcon: "wifi"
    fallbackText: Nmcli.wifiDevice
    menuItems: items.instances
    active: menuItems.find(i => i.value === Nmcli.wifiDevice) ?? null
    stateLayer.onClicked: expanded = !expanded
    menu.onItemSelected: item => Nmcli.selectDevice(item.value)

    Variants {
        id: items

        model: Nmcli.wirelessInterfaces

        MenuItem {
            required property var modelData

            text: root.label(modelData)
            icon: Nmcli.isConnectedState(modelData.state) ? "wifi" : "wifi_off"
            value: modelData.device
        }
    }
}
