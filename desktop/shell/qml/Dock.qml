// SPDX-License-Identifier: MIT
import QtQuick
import "Theme.js" as Theme

Item {
    id: root
    property var colors: Theme.colors(shell.theme)
    implicitHeight: 82

    Rectangle {
        id: shelf
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: Math.min(parent.width - 16, dockRow.implicitWidth + 28)
        height: 66
        radius: 24
        color: root.colors.panel
        border.width: 1
        border.color: root.colors.border
        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8
            Item {
                width: 48; height: 52
                Rectangle {
                    anchors.centerIn: parent
                    width: 45; height: 45; radius: 16
                    color: launcherMouse.containsMouse ? root.colors.hover : root.colors.card
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                FlowerMark {
                    anchors.centerIn: parent
                    width: 28; height: 28
                    petalColor: root.colors.accent
                }
                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shell.toggleLauncherForScreen(screenName)
                }
            }
            Rectangle {
                y: 12; width: 1; height: 29
                color: root.colors.border
            }
            Repeater {
                model: shell.dockApps
                delegate: Item {
                    width: 48; height: 52
                    property var appData: modelData
                    Rectangle {
                        anchors.centerIn: parent
                        width: 45; height: 45; radius: 16
                        color: appMouse.containsMouse ? root.colors.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: "image://hde-icon/" + appData.icon + "?theme=" + shell.theme
                        sourceSize: Qt.size(64, 64)
                        smooth: true
                        scale: appMouse.containsMouse ? 1.12 : 1
                        Behavior on scale { NumberAnimation { duration: 135; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shell.launchDesktopId(appData.id)
                    }
                }
            }
        }
    }
}
