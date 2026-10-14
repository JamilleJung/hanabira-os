// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Item {
    id: root
    property var colors: Theme.colors(shell.theme)
    Keys.onEscapePressed: shell.hidePopups()
    Rectangle {
        anchors.fill: parent
        color: shell.theme === "dream" ? "#67483E62" : "#9B090D1B"
        MouseArea { anchors.fill: parent; onClicked: shell.hidePopups() }
    }
    Rectangle {
        id: sheet
        width: Math.min(root.width - 24, 370)
        height: Math.min(root.height - 84, shell.mediaAvailable ? 560 : 440)
        x: Math.max(12, root.width - width - 18)
        y: 62
        radius: 27
        color: root.colors.sheet
        border.width: 1
        border.color: root.colors.border
        MouseArea { anchors.fill: parent; onClicked: {} }
        Flickable {
            id: scroll
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: shell.mediaAvailable ? 550 : 420
            boundsBehavior: Flickable.StopAtBounds
            Item {
                width: scroll.width
                height: scroll.contentHeight

        Text {
            x: 24; y: 20
            text: qsTr("Quick settings")
            color: root.colors.text
            font.family: "Prompt"
            font.pixelSize: 19
            font.weight: Font.Bold
        }
        Text {
            x: 24; y: 58
            text: qsTr("Appearance")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
        Row {
            x: 24; y: 82
            spacing: 7
            Repeater {
                model: [
                    {id: "dream", title: "Sakura", color: "#E7A3C4"},
                    {id: "midnight", title: "Night", color: "#70557C"},
                    {id: "celestial", title: "Blue", color: "#5E90C4"}
                ]
                delegate: Rectangle {
                    width: Math.max(79, (sheet.width - 62) / 3)
                    height: 69
                    radius: 15
                    color: root.colors.card
                    border.width: shell.theme === modelData.id ? 2 : 1
                    border.color: shell.theme === modelData.id ? root.colors.accent : root.colors.border
                    Rectangle {
                        x: 12; y: 12; width: 19; height: 19; radius: 10
                        color: modelData.color
                    }
                    Text {
                        x: 12; y: 36
                        text: modelData.title
                        color: root.colors.text
                        font.family: "Prompt"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shell.setTheme(modelData.id)
                    }
                }
            }
        }
        Rectangle {
            x: 24; y: 167
            width: parent.width - 48; height: 1
            color: root.colors.border
        }
        Text {
            x: 24; y: 182
            text: qsTr("SOUND")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
        Item {
            id: volumeControl
            visible: shell.volumeAvailable
            x: 24; y: 212
            width: parent.width - 48; height: 54
            Rectangle {
                id: muteButton
                x: 0; y: 4; width: 46; height: 46; radius: 15
                color: root.colors.card
                Text {
                    anchors.centerIn: parent
                    text: shell.muted ? "◌" : "♫"
                    color: root.colors.text
                    font.family: "Prompt"
                    font.pixelSize: 20
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shell.toggleMute()
                }
            }
            Slider {
                id: volumeSlider
                x: 59; y: 8
                width: Math.max(60, parent.width - 107)
                from: 0; to: 100
                value: shell.volume
                enabled: shell.volumeAvailable
                onMoved: volumeDelay.restart()
                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 5
                    radius: 3
                    color: root.colors.border
                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: root.colors.accent
                    }
                }
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 16; height: 16; radius: 8
                    color: root.colors.accent
                }
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(volumeSlider.value) + "%"
                color: root.colors.text
                font.family: "Prompt"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Timer {
                id: volumeDelay
                interval: 70
                repeat: false
                onTriggered: shell.setVolume(Math.round(volumeSlider.value))
            }
        }
        Text {
            visible: !shell.volumeAvailable
            x: 24; y: 220
            text: qsTr("Audio device unavailable")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 12
        }
        Rectangle {
            x: 24; y: 283
            width: parent.width - 48; height: 1
            color: root.colors.border
        }
        Text {
            x: 24; y: 300
            text: qsTr("POWER")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
        Text {
            x: 24; y: 325
            text: shell.batteryAvailable ? shell.batteryPercent + "% · " + shell.batteryStatus : qsTr("Battery not present")
            color: root.colors.text
            font.family: "Prompt"
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Text {
            x: 24; y: shell.mediaAvailable ? 526 : 390
            text: "HANABIRA OS  ·  PREVIEW"
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Rectangle {
            visible: shell.mediaAvailable
            x: 24; y: 361
            width: parent.width - 48; height: 1
            color: root.colors.border
        }
        Text {
            visible: shell.mediaAvailable
            x: 24; y: 377
            text: qsTr("NOW PLAYING")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
        Rectangle {
            visible: shell.mediaAvailable
            x: 24; y: 403
            width: parent.width - 48; height: 108
            radius: 17
            color: root.colors.card
            Image {
                id: albumArt
                x: 10; y: 10; width: 51; height: 51
                source: shell.mediaArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true
            }
            FlowerMark {
                visible: !albumArt.visible
                x: 19; y: 19; width: 33; height: 33
                petalColor: root.colors.accent
            }
            Text {
                x: 70; y: 11
                width: parent.width - 80
                text: shell.mediaTitle || qsTr("Untitled track")
                color: root.colors.text
                font.family: "Prompt"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                x: 70; y: 33
                width: parent.width - 80
                text: shell.mediaArtist || qsTr("Unknown artist")
                color: root.colors.muted
                font.family: "Prompt"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Row {
                x: 70; y: 67
                spacing: 5
                Repeater {
                    model: [
                        {label: qsTr("Prev"), enabled: shell.mediaCanPrevious, action: "previous"},
                        {label: shell.mediaPlaying ? qsTr("Pause") : qsTr("Play"), enabled: true, action: "playpause"},
                        {label: qsTr("Next"), enabled: shell.mediaCanNext, action: "next"}
                    ]
                    delegate: Rectangle {
                        width: 62; height: 29; radius: 10
                        color: modelData.action === "playpause" ? root.colors.accent : root.colors.sheet
                        opacity: modelData.enabled ? 1 : 0.45
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: modelData.action === "playpause" ? root.colors.accentText : root.colors.text
                            font.family: "Prompt"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "previous") shell.mediaPrevious()
                                else if (modelData.action === "next") shell.mediaNext()
                                else shell.mediaPlayPause()
                            }
                        }
                    }
                }
            }
        }
            }
        }
    }
}
