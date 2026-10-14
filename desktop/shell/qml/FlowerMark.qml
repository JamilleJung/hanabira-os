// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: mark
    property color petalColor: "#D989AC"
    property color centerColor: "#FFE8B7"
    Repeater {
        model: 5
        delegate: Rectangle {
            width: mark.width * 0.34
            height: mark.height * 0.52
            radius: width * 0.55
            x: (mark.width - width) / 2
            y: mark.height * 0.06
            color: mark.petalColor
            antialiasing: true
            transform: Rotation {
                angle: index * 72
                origin.x: width / 2
                origin.y: mark.height * 0.44
            }
        }
    }
    Rectangle {
        width: mark.width * 0.24
        height: width
        radius: width / 2
        anchors.centerIn: parent
        color: mark.centerColor
        antialiasing: true
    }
}
