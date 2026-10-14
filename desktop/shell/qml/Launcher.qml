// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "Theme.js" as Theme

Item {
    id: root
    property var colors: Theme.colors(shell.theme)
    property var categories: ["All", "Network", "Development", "Graphics", "AudioVideo", "System"]
    signal dismissed()
    Keys.onEscapePressed: shell.hidePopups()

    Rectangle {
        anchors.fill: parent
        color: shell.theme === "dream" ? "#67483E62" : "#9B090D1B"
        MouseArea { anchors.fill: parent; onClicked: shell.hidePopups() }
    }
    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(root.width - 28, 750)
        height: Math.min(root.height - 82, 655)
        radius: 30
        color: root.colors.sheet
        border.width: 1
        border.color: root.colors.border
        clip: true
        MouseArea { anchors.fill: parent; onClicked: {} }

        FlowerMark {
            id: emblem
            x: 32; y: 27
            width: 28; height: 28
            petalColor: root.colors.accent
        }
        Text {
            x: 71; y: 26
            text: "HANABIRA"
            color: root.colors.text
            font.family: "Prompt"
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }
        Text {
            x: 34; y: 64
            text: qsTr("Find an application")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 12
        }
        TextField {
            id: searchField
            x: 28; y: 91
            width: parent.width - 56
            height: 49
            placeholderText: qsTr("Search apps by name or description…")
            font.family: "Prompt"
            font.pixelSize: 15
            color: root.colors.text
            placeholderTextColor: root.colors.muted
            selectionColor: root.colors.accent
            selectedTextColor: root.colors.accentText
            selectByMouse: true
            leftPadding: 17
            rightPadding: 17
            background: Rectangle {
                radius: 15
                color: root.colors.card
                border.color: searchField.activeFocus ? root.colors.accent : root.colors.border
                border.width: searchField.activeFocus ? 2 : 1
            }
            onTextChanged: shell.apps.query = text
            onAccepted: shell.launchResult(0)
            Keys.onDownPressed: appList.forceActiveFocus()
            Component.onCompleted: {
                if (previewQuery !== "") text = previewQuery
            }
        }

        Flickable {
            id: categoryScroll
            x: 28; y: 153
            width: parent.width - 56; height: 38
            contentWidth: categoryRow.width
            clip: true
            Row {
                id: categoryRow
                spacing: 7
                Repeater {
                    model: root.categories
                    delegate: Rectangle {
                        width: categoryText.implicitWidth + 24
                        height: 30
                        radius: 12
                        color: shell.apps.category === modelData ? root.colors.accent : root.colors.card
                        Text {
                            id: categoryText
                            anchors.centerIn: parent
                            text: modelData === "All" ? qsTr("All") : modelData === "AudioVideo" ? qsTr("Media") : modelData
                            color: shell.apps.category === modelData ? root.colors.accentText : root.colors.text
                            font.family: "Prompt"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shell.apps.category = modelData
                        }
                    }
                }
            }
        }

        Rectangle { x: 28; y: 198; width: parent.width - 56; height: 1; color: root.colors.border }

        ListView {
            id: appList
            x: 21; y: 208
            width: parent.width - 42
            height: Math.max(0, parent.height - 266)
            clip: true
            model: shell.apps
            spacing: 3
            keyNavigationWraps: true
            Keys.onReturnPressed: shell.launchResult(currentIndex)
            Keys.onEnterPressed: shell.launchResult(currentIndex)
            delegate: Rectangle {
                width: appList.width
                height: 57
                radius: 14
                color: appMouse.containsMouse || ListView.isCurrentItem ? root.colors.hover : "transparent"
                Image {
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 36
                    source: "image://hde-icon/" + iconName + "?theme=" + shell.theme
                    sourceSize: Qt.size(72, 72)
                }
                Text {
                    id: appName
                    x: 62; y: 7
                    width: parent.width - 76
                    text: name
                    color: root.colors.text
                    font.family: "Prompt"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    x: 62; y: 30
                    width: parent.width - 76
                    text: description
                    color: root.colors.muted
                    font.family: "Prompt"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shell.launchResult(index)
                }
            }
            Text {
                visible: appList.count === 0
                anchors.centerIn: parent
                text: searchField.text ? qsTr("No matching applications") : qsTr("No applications installed")
                color: root.colors.muted
                font.family: "Prompt"
                font.pixelSize: 13
            }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 34
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 17
            text: qsTr("Enter to open  ·  Esc to close")
            color: root.colors.muted
            font.family: "Prompt"
            font.pixelSize: 11
        }
    }

    Connections {
        target: root.Window.window
        function onVisibleChanged() {
            if (root.Window.window.visible) {
                searchField.text = previewQuery
                shell.apps.category = "All"
                searchField.forceActiveFocus()
            }
        }
    }
}
