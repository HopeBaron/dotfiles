// Login screen, laid out to match hyprlock.conf so logging in and unlocking
// look like the same screen. Colours come from theme.conf (rendered from
// theme/palette.sh) -- no hex values belong in this file.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.bg0

    readonly property string fontFamily: config.font
    readonly property int fieldWidth: 307
    readonly property int fieldHeight: 34
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

    // Wallpaper, blurred like hyprlock's `blur_passes = 3, blur_size = 7`.
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        autoPaddingEnabled: false
    }
    Rectangle { anchors.fill: parent; color: root.tint(config.bg0, 0.35) }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            clock.text = Qt.formatTime(now, "HH:mm")
            date.text = Qt.formatDate(now, "dddd, dd MMMM")
        }
    }

    Text {
        id: clock
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -160
        color: config.fg0
        font { family: root.fontFamily; pixelSize: 90 }
    }

    Text {
        id: date
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -90
        color: config.grey2
        font { family: root.fontFamily; pixelSize: 20 }
    }

    // ---- Username / password / Login. Same geometry as hyprlock.conf. ----

    component Field: Rectangle {
        property bool alert: false
        width: root.fieldWidth
        height: root.fieldHeight
        radius: 4
        color: root.tint(config.bg1, 0.85)
        border.width: 1
        border.color: alert ? config.red : config.bg5
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    component Placeholder: Text {
        anchors.centerIn: parent
        color: config.grey1
        font { family: root.fontFamily; pixelSize: 13; bold: true }
    }

    Column {
        id: form
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        spacing: 8

        // Username, prefilled with the last user. The chevron opens the
        // account list; typing here works for any account ("Other…").
        Field {
            id: userField
            TextInput {
                id: username
                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                text: userModel.lastUser
                color: config.fg0
                selectionColor: config.green
                selectedTextColor: config.bg0
                font { family: root.fontFamily; pixelSize: 13; bold: true }
                clip: true
                enabled: !root.checking
                KeyNavigation.tab: password
                Keys.onReturnPressed: password.forceActiveFocus()
                Keys.onEnterPressed: password.forceActiveFocus()
                Keys.onDownPressed: userMenu.visible = true
                Keys.onEscapePressed: root.closeMenus()
            }
            Placeholder { visible: username.text.length === 0; text: "Username" }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: userMenu.visible ? "" : ""
                color: chevronArea.containsMouse || userMenu.visible ? config.fg0 : config.grey1
                font { family: config.iconFont; pixelSize: 11 }
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

        // Red outline on failure, like hyprlock's fail_color.
        Field {
            alert: root.failed
            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: config.green
                selectionColor: config.green
                selectedTextColor: config.bg0
                font { family: root.fontFamily; pixelSize: 13; bold: true }
                clip: true
                enabled: !root.checking
                KeyNavigation.backtab: username
                onTextEdited: root.failed = false
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                Keys.onEscapePressed: {
                    if (userMenu.visible || sessionMenu.visible) root.closeMenus()
                    else text = ""
                }
            }
            Placeholder {
                visible: password.text.length === 0
                color: root.failed ? config.red
                     : keyboard.capsLock ? config.yellow
                     : config.grey1
                text: root.failed ? "Login failed"
                    : keyboard.capsLock ? "Caps Lock"
                    : "Password"
            }
        }

        Rectangle {
            width: root.fieldWidth
            height: root.fieldHeight
            radius: 4
            color: loginArea.pressed ? root.tint(config.green, 0.75)
                 : loginArea.containsMouse ? root.tint(config.green, 0.88)
                 : config.green
            Text {
                anchors.centerIn: parent
                text: root.checking ? "Logging in..." : "Login"
                color: config.bg0
                font { family: root.fontFamily; pixelSize: 13; bold: true }
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

    // Session + power, drawn as one of waybar's floating islands.
    // Icon in the Nerd Font, label in the UI font (the icon font centres its
    // glyphs on that text line; the UI font itself has none).
    component IslandButton: Text {
        id: btn
        property string icon
        property string label
        property color hoverColor: config.green
        property bool active: false
        signal activated()
        height: parent.height
        leftPadding: 10
        rightPadding: 10
        verticalAlignment: Text.AlignVCenter
        color: area.containsMouse || active ? hoverColor : config.fg0
        textFormat: Text.StyledText
        text: '<font face="' + config.iconFont + '">' + icon + '</font>'
            + (label ? "&nbsp;&nbsp;" + label.replace(/&/g, "&amp;").replace(/</g, "&lt;") : "")
        font { family: root.fontFamily; pixelSize: 13 }
        Behavior on color { ColorAnimation { duration: 150 } }
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
        anchors.margins: 10
        width: island.implicitWidth + 8
        height: 38
        radius: 10
        color: root.tint(config.bg0, 0.92)
        border.width: 1
        border.color: root.tint(config.bg3, 0.8)

        Row {
            id: island
            anchors.centerIn: parent
            height: parent.height

            IslandButton {
                icon: "󰍹"
                label: sessions.count > 0 ? sessions.itemAt(root.sessionIndex).name : ""
                active: sessionMenu.visible
                onActivated: {
                    userMenu.visible = false
                    sessionMenu.visible = !sessionMenu.visible
                }
            }
            Rectangle {
                width: 1
                height: parent.height - 16
                anchors.verticalCenter: parent.verticalCenter
                color: root.tint(config.bg5, 0.7)
            }
            IslandButton { icon: "󰒲"; visible: sddm.canSuspend; onActivated: sddm.suspend() }
            IslandButton { icon: "󰜉"; visible: sddm.canReboot; onActivated: sddm.reboot() }
            IslandButton {
                icon: "⏻"
                hoverColor: config.red
                visible: sddm.canPowerOff
                onActivated: sddm.powerOff()
            }
        }
    }

    // ---- Drop-down lists (rofi-like: island background, ● marks current) ----

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
        height: 30
        radius: 7
        color: rowArea.containsMouse ? root.tint(config.bg3, 0.6) : "transparent"
        readonly property real naturalWidth: rowText.implicitWidth + 44
        Text {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "●"
            visible: row.marked
            color: config.green
            font { family: root.fontFamily; pixelSize: 10 }
        }
        Text {
            id: rowText
            x: 30
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            color: row.marked ? config.green : config.fg0
            font { family: root.fontFamily; pixelSize: 13 }
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
        property real rowWidth: 180
        visible: false
        width: rowWidth + 8
        height: column.implicitHeight + 8
        radius: 10
        color: root.tint(config.bg0, 0.96)
        border.width: 1
        border.color: root.tint(config.bg3, 0.8)
        Column { id: column; anchors.centerIn: parent }
    }

    Menu {
        id: userMenu
        x: form.x
        y: form.y + userField.height + 4
        rowWidth: root.fieldWidth - 8

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
        anchors.bottomMargin: 6

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
