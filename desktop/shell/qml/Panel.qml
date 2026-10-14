// SPDX-License-Identifier: MIT
import QtQuick
import "Theme.js" as Theme

Item {
    id: root
    property var colors: Theme.colors(shell.theme)
    implicitHeight: 54

    Rectangle {
        id: surface
        x: 12; y: 6
        width: parent.width - 24
        height: 42
        radius: 17
        color: root.colors.panel
        border.width: 1
        border.color: root.colors.border
    }

    Item {
        id: launchButton
        x: 23; y: 8
        width: 38; height: 38
        FlowerMark {
            anchors.centerIn: parent
            width: 23; height: 23
            petalColor: root.colors.accent
            centerColor: shell.theme === "dream" ? "#FFF9E9" : "#FFE4B0"
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: shell.toggleLauncherForScreen(screenName)
            cursorShape: Qt.PointingHandCursor
        }
    }

    Rectangle {
        x: 65; y: 17; width: 1; height: 20
        color: root.colors.border
    }
    Text {
        x: 79; y: 15
        text: "HANABIRA"
        color: root.colors.text
        font.family: "Prompt"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.letterSpacing: 2.1
    }
    Text {
        x: 200; y: 17
        visible: parent.width > 880
        text: shell.theme === "celestial" ? "CELESTIAL  /  夜空" : shell.theme === "midnight" ? "MIDNIGHT  /  夜桜" : "SAKURA MOTION  /  春"
        color: root.colors.muted
        font.family: "Prompt"
        font.pixelSize: 11
        font.weight: Font.Medium
        font.letterSpacing: 1.1
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 26
        y: 8
        height: 38
        spacing: 7
        Item {
            visible: shell.batteryAvailable && root.width > 520
            width: visible ? batteryLabel.implicitWidth + 18 : 0
            height: 38
            Text {
                id: batteryLabel
                anchors.centerIn: parent
                text: shell.batteryPercent + "%"
                color: root.colors.muted
                font.family: "Prompt"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
        Item {
            visible: shell.volumeAvailable && root.width > 420
            width: visible ? 45 : 0
            height: 38
            Text {
                anchors.centerIn: parent
                text: shell.muted ? "◌" : "♫"
                color: root.colors.text
                font.family: "Prompt"
                font.pixelSize: 18
            }
            MouseArea {
                anchors.fill: parent
                onClicked: shell.toggleQuickSettingsForScreen(screenName)
                cursorShape: Qt.PointingHandCursor
            }
        }
        Rectangle {
            y: 8
            width: clockText.implicitWidth + 18
            height: 23
            radius: 10
            color: root.colors.card
            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatTime(new Date(), "hh:mm")
                color: root.colors.text
                font.family: "Prompt"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm") }
        }
        Item {
            width: 34; height: 38
            Text {
                anchors.centerIn: parent
                text: "☷"
                color: root.colors.text
                font.pixelSize: 19
                font.weight: Font.Bold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: shell.toggleQuickSettingsForScreen(screenName)
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
