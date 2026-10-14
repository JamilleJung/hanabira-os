// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Item {
    id: root
    property var colors: Theme.colors(shell.theme)

    Image {
        anchors.fill: parent
        source: shell.wallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: shell.theme === "dream" ? "#0A684C72" : "#1820143D"
    }

    // Right-click actions are real shell actions, not a decorative menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: desktopMenu.popup()
    }
    Menu {
        id: desktopMenu
        MenuItem { text: qsTr("Open applications"); onTriggered: shell.toggleLauncherForScreen(screenName) }
        MenuItem { text: qsTr("Quick settings"); onTriggered: shell.toggleQuickSettingsForScreen(screenName) }
    }

    GridView {
        id: desktopGrid
        visible: primaryScreen && count > 0
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.topMargin: 72
        width: Math.min(440, parent.width * 0.4)
        height: Math.max(0, parent.height - 180)
        cellWidth: 96
        cellHeight: 100
        model: shell.desktop
        clip: true
        delegate: Item {
            width: desktopGrid.cellWidth
            height: desktopGrid.cellHeight
            Rectangle {
                id: iconTile
                anchors.horizontalCenter: parent.horizontalCenter
                y: 5; width: 58; height: 58; radius: 17
                color: root.colors.panel
                border.color: root.colors.border
                Image {
                    anchors.centerIn: parent
                    width: 42; height: 42
                    source: "image://hde-icon/" + iconName + "?theme=" + shell.theme
                    sourceSize: Qt.size(64, 64)
                }
            }
            Text {
                anchors.top: iconTile.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: 88
                text: name
                color: shell.theme === "dream" ? "#33283D" : "#FFF5FB"
                font.family: "Prompt"
                font.pixelSize: 12
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: shell.theme === "dream" ? "#C8FFF9FC" : "#C8201E34"
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onDoubleClicked: shell.desktop.openAt(index)
            }
        }
    }

    Rectangle {
        visible: shell.lastError !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 102
        width: Math.min(parent.width - 32, 500)
        height: 48
        radius: 14
        color: root.colors.sheet
        border.color: root.colors.accent
        Text {
            anchors.centerIn: parent
            width: parent.width - 32
            text: shell.lastError
            color: root.colors.text
            font.family: "Prompt"
            font.pixelSize: 13
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea { anchors.fill: parent; onClicked: shell.clearError() }
    }
}
