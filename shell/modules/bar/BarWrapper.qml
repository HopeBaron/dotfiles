pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.State
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered || eventReveal)
    property bool isHovered
    // Shown for a moment when something happens (workspace switch, urgent window, new notification).
    property bool eventReveal
    property int notifCount: -1

    function reveal(ms: int): void {
        eventReveal = true;
        revealTimer.interval = ms;
        revealTimer.restart();
    }

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(y: real): void {
        (content.item as Bar)?.checkPopout(y);
    }

    function handleWheel(y: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(y, angleDelta);
    }

    Timer {
        id: revealTimer

        onTriggered: root.eventReveal = false
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (["workspace", "activespecial"].includes(event.name))
                root.reveal(2000);
            else if (event.name === "urgent")
                root.reveal(4000);
        }

        target: Hyprland
    }

    Connections {
        function onListChanged(): void {
            // Only a longer list is a new notification (closing one shortens it).
            if (Notifs.loaded && root.notifCount >= 0 && Notifs.list.length > root.notifCount && !PersistentState.doNotDisturb)
                root.reveal(4000);
            root.notifCount = Notifs.list.length;
        }

        target: Notifs
    }

    clip: true
    visible: width > Config.border.thickness
    implicitWidth: fullscreen ? 0 : Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
            fullscreen: root.fullscreen
        }
    }
}
