import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property string launcherPrefill // search text to start the launcher with (e.g. ">shortcut ")
    property bool liveFocus // the launcher is moving window focus as you browse (windows mode)
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
