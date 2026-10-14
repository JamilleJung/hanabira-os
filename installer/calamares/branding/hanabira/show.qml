import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    Slide {
        Image {
            anchors.fill: parent
            source: "welcome.png"
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.4
            color: "#221a32"
            opacity: 0.88
        }
        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 28
            text: qsTr("A new space to create, play and explore.")
            color: "#fff4f9"
            font.family: "Prompt"
            font.pixelSize: 24
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }
    }
}
