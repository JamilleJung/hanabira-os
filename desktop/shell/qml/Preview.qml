// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: root
    Wallpaper { anchors.fill: parent }
    Panel { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top }
    Dock {
        width: Math.min(570, root.width * 0.82)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
    Launcher {
        id: launcher
        anchors.fill: parent
        visible: previewLauncher
    }
    QuickSettings {
        id: quickSettings
        anchors.fill: parent
        visible: previewQuickSettings
    }
    Connections {
        target: shell
        function onLauncherRequested(screenName, visible) {
            launcher.visible = visible
            if (visible) quickSettings.visible = false
        }
        function onQuickSettingsRequested(screenName, visible) {
            quickSettings.visible = visible
            if (visible) launcher.visible = false
        }
    }
}
