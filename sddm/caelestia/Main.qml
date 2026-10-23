// Login screen in the look of the Caelestia shell: Material surfaces, Rubik,
// Material Symbols. Every colour comes from theme.conf (rendered from the
// active scheme by sddm/install.sh) -- no hex values belong in this file.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.background

    readonly property string fontFamily: config.font
    readonly property string iconFamily: config.iconFont
    readonly property int cardWidth: 380
    property int sessionIndex: sessionModel.lastIndex
    property bool checking: false
    property bool failed: false

    function tint(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function closeMenus() { userMenu.visible = false; sessionMenu.visible = false }
    function login() {
        if (checking) return
        if (username.text === "") { username.forceActiveFocus(); return }
        closeMenus()
        checking = true
        failed = false
        sddm.login(username.text, password.text, sessionIndex)
    }

    readonly property alias username: userField
    readonly property alias password: passwordField

    Component.onCompleted: (username.text === "" ? username : password).forceActiveFocus()

    // Invisible mirror of the session model, so names can be read by index.
    Repeater { id: sessions; model: sessionModel; delegate: Item { required property string name } }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.checking = false
            root.failed = true
            password.text = ""
            password.forceActiveFocus()
        }
    }

    // The wallpaper the shell was using when install.sh last ran (the greeter
    // runs as the sddm user and cannot read your home), blurred and dimmed.
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background_image ? Qt.resolvedUrl(config.background_image) : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 0.8
        autoPaddingEnabled: false
    }
    Rectangle { anchors.fill: parent; color: root.tint(config.background, 0.5) }

    component Icon: Text {
        font { family: root.iconFamily; pixelSize: 22 }
        color: config.onSurfaceVariant
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    // One look for both fields, as on the shell's lock screen: the placeholder
    // sits centred and fades out, and each typed character pops in (a shape for
    // the password, the letter itself for the account) and settles.
    component Field: FocusScope {
        id: field
        property string icon
        property string placeholder
        property color placeholderColor: config.outline
        property bool secret: false
        property bool error: false
        property alias text: input.text
        default property alias extra: bg.data
        signal accepted()
        signal escaped()
        signal down()
        signal tabbed()
        signal backtabbed()
        signal edited()

        width: parent.width
        height: 52

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 26
            color: config.surfaceContainerHigh
            border.width: 2
            border.color: field.error ? config.error : "transparent"
            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }

            Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; text: field.icon }

            TextInput {
                id: input
                anchors.fill: parent
                opacity: 0
                focus: true
                echoMode: field.secret ? TextInput.Password : TextInput.Normal
                onTextEdited: field.edited()
                Keys.onReturnPressed: field.accepted()
                Keys.onEnterPressed: field.accepted()
                Keys.onEscapePressed: field.escaped()
                Keys.onDownPressed: field.down()
                Keys.onTabPressed: field.tabbed()
                Keys.onBacktabPressed: field.backtabbed()
            }

            Text {
                anchors.centerIn: parent
                text: field.placeholder
                color: field.placeholderColor
                font { family: root.fontFamily; pixelSize: 16 }
                opacity: input.text.length === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item {
                id: clipArea
                anchors.fill: parent
                anchors.leftMargin: 52
                anchors.rightMargin: 52
                clip: true

                Row {
                    id: chars
                    height: parent.height
                    spacing: field.secret ? 4 : 0
                    x: width > clipArea.width ? clipArea.width - width : (clipArea.width - width) / 2
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    Repeater {
                        model: input.text.length
                        delegate: Item {
                            id: ch
                            required property int index
                            // Pops in oversized, then settles a moment later.
                            property bool settled: false
                            property bool shown: false

                            height: chars.height
                            width: field.secret ? (settled ? 11 : 16) : letter.implicitWidth
                            scale: shown ? 1 : 0
                            opacity: shown ? 1 : 0

                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Timer { interval: 180; running: true; onTriggered: ch.settled = true }
                            Component.onCompleted: shown = true

                            // Password: starts as an odd shape, then relaxes to a dot.
                            Rectangle {
                                visible: field.secret
                                anchors.centerIn: parent
                                width: ch.settled ? 11 : 16
                                height: width
                                radius: ch.settled ? width / 2 : 4
                                rotation: ch.settled ? 0 : [45, 20, -25, 0][ch.index % 4]
                                color: config.onSurface
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            // Account: the letter itself.
                            Text {
                                id: letter
                                visible: !field.secret
                                anchors.centerIn: parent
                                text: input.text[ch.index] ?? ""
                                color: config.onSurface
                                font { family: root.fontFamily; pixelSize: 16 }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            clock.text = Qt.formatTime(now, "HH:mm")
            date.text = Qt.formatDate(now, "dddd, d MMMM")
        }
    }

    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 56
        color: config.onSurface
        font { family: root.fontFamily; pixelSize: 112; weight: Font.Light }
    }
    Text {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom
        anchors.topMargin: -6
        color: config.onSurfaceVariant
        font { family: root.fontFamily; pixelSize: 20 }
    }

    // ---- Card: account, password, Login ----

    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 110
        width: root.cardWidth
        height: form.implicitHeight + 48
        radius: 28
        color: root.tint(config.surfaceContainer, 0.88)
        border.width: 1
        border.color: root.tint(config.outlineVariant, 0.6)

        Column {
            id: form
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 12

            // Account, prefilled with the last user. The chevron opens the
            // list; typing works for any account ("Other…").
            Field {
                id: userField
                icon: "account_circle"
                placeholder: "Username"
                text: userModel.lastUser
                enabled: !root.checking
                onAccepted: password.forceActiveFocus()
                onTabbed: password.forceActiveFocus()
                onDown: userMenu.visible = true
                onEscaped: root.closeMenus()

                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: userMenu.visible ? "expand_less" : "expand_more"
                    color: chevronArea.containsMouse || userMenu.visible ? config.onSurface : config.onSurfaceVariant
                    MouseArea {
                        id: chevronArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sessionMenu.visible = false
                            userMenu.visible = !userMenu.visible
                        }
                    }
                }
            }

            // Outlined in the error colour on failure.
            Field {
                id: passwordField
                icon: "lock"
                secret: true
                error: root.failed
                enabled: !root.checking
                placeholder: root.failed ? "Login failed"
                    : keyboard.capsLock ? "Caps Lock is on"
                    : "Password"
                placeholderColor: root.failed ? config.error
                    : keyboard.capsLock ? config.tertiary
                    : config.outline
                onEdited: root.failed = false
                onAccepted: root.login()
                onBacktabbed: username.forceActiveFocus()
                onEscaped: {
                    if (userMenu.visible || sessionMenu.visible) root.closeMenus()
                    else text = ""
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                radius: 26
                color: loginArea.pressed ? root.tint(config.primary, 0.75)
                     : loginArea.containsMouse ? root.tint(config.primary, 0.9)
                     : config.primary
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: root.checking ? "Logging in…" : "Login"
                    color: config.onPrimary
                    font { family: root.fontFamily; pixelSize: 16; weight: Font.Medium }
                }
                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.login()
                }
            }
        }
    }

    // ---- Session, keyboard layout and power: one pill bottom right ----

    component PillButton: Rectangle {
        id: btn
        property string icon
        property string label
        property color hoverColor: config.primary
        property bool active: false
        signal activated()
        height: 40
        width: content.implicitWidth + 24
        radius: 20
        color: area.containsMouse || active ? root.tint(config.onSurface, 0.1) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8
            Icon {
                visible: btn.icon !== ""
                text: btn.icon
                color: area.containsMouse || btn.active ? btn.hoverColor : config.onSurface
            }
            Text {
                visible: btn.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: area.containsMouse || btn.active ? btn.hoverColor : config.onSurface
                font { family: root.fontFamily; pixelSize: 14 }
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }

    Rectangle {
        id: bar
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        width: island.implicitWidth + 16
        height: 56
        radius: 28
        color: root.tint(config.surfaceContainer, 0.88)
        border.width: 1
        border.color: root.tint(config.outlineVariant, 0.6)

        Row {
            id: island
            anchors.centerIn: parent
            spacing: 2

            PillButton {
                icon: "keyboard"
                // keyboard.layouts holds layout objects (shortName/longName).
                label: keyboard.layouts.length > 0
                    ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
                onActivated: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
            PillButton {
                icon: "desktop_windows"
                label: sessions.count > 0 ? sessions.itemAt(root.sessionIndex).name : ""
                active: sessionMenu.visible
                onActivated: {
                    userMenu.visible = false
                    sessionMenu.visible = !sessionMenu.visible
                }
            }
            PillButton { icon: "bedtime"; visible: sddm.canSuspend; onActivated: sddm.suspend() }
            PillButton { icon: "restart_alt"; visible: sddm.canReboot; onActivated: sddm.reboot() }
            PillButton {
                icon: "power_settings_new"
                hoverColor: config.error
                visible: sddm.canPowerOff
                onActivated: sddm.powerOff()
            }
        }
    }

    // ---- Drop-down lists (● marks the current choice) ----

    // Clicking anywhere outside an open list closes it.
    MouseArea {
        anchors.fill: parent
        visible: userMenu.visible || sessionMenu.visible
        onClicked: { root.closeMenus(); password.forceActiveFocus() }
    }

    component MenuRow: Rectangle {
        id: row
        property string label
        property bool marked: false
        property real minWidth: 0
        signal picked()
        width: minWidth
        height: 40
        radius: 20
        color: rowArea.containsMouse ? root.tint(config.onSurface, 0.1) : "transparent"
        readonly property real naturalWidth: rowText.implicitWidth + 56
        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "●"
            visible: row.marked
            color: config.primary
            font { family: root.fontFamily; pixelSize: 10 }
        }
        Text {
            id: rowText
            x: 36
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            color: row.marked ? config.primary : config.onSurface
            font { family: root.fontFamily; pixelSize: 15 }
        }
        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked()
        }
    }

    component Menu: Rectangle {
        default property alias rows: column.data
        property real rowWidth: 200
        visible: false
        width: rowWidth + 16
        height: column.implicitHeight + 16
        radius: 24
        color: root.tint(config.surfaceContainerHigh, 0.97)
        border.width: 1
        border.color: root.tint(config.outlineVariant, 0.6)
        Column { id: column; anchors.centerIn: parent }
    }

    Menu {
        id: userMenu
        x: card.x + 24
        y: card.y + 24 + userField.height + 6
        rowWidth: card.width - 48 - 16

        Repeater {
            model: userModel
            delegate: MenuRow {
                required property string name
                label: name
                marked: name === username.text
                minWidth: userMenu.rowWidth
                onPicked: {
                    username.text = name
                    root.closeMenus()
                    password.forceActiveFocus()
                }
            }
        }
        MenuRow {
            label: "Other…"
            minWidth: userMenu.rowWidth
            onPicked: {
                root.closeMenus()
                username.text = ""
                username.forceActiveFocus()
            }
        }
    }

    Menu {
        id: sessionMenu
        anchors.right: bar.right
        anchors.bottom: bar.top
        anchors.bottomMargin: 8

        Repeater {
            model: sessionModel
            delegate: MenuRow {
                required property string name
                required property int index
                label: name
                marked: index === root.sessionIndex
                minWidth: sessionMenu.rowWidth
                Component.onCompleted: sessionMenu.rowWidth = Math.max(sessionMenu.rowWidth, naturalWidth)
                onPicked: {
                    root.sessionIndex = index
                    root.closeMenus()
                    password.forceActiveFocus()
                }
            }
        }
    }
}
