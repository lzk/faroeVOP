import QtQuick 2.0
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0

Window {
    id:window
    property alias container: container
    property alias background: background
    property alias toolbar: jKToolbar
    property var dialog
    flags: Qt.Dialog | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal // Qt.WindowModal

    Item{
        anchors.fill: parent
        anchors.margins: 10
        visible: window.visible

        RectangularGlow{
            anchors.fill: parent
            glowRadius: 10
            spread: 0.2
            color: "#FF858484"
            cornerRadius: glowRadius
        }

        Item{
            id:background
            anchors.fill: parent
        }


        JKToolbar {
            id: jKToolbar
            anchors.top:parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.bottomMargin: -30
            z:10
            onClose: {window.close();dialog=undefined}
            onMovedXChanged: window.x += movedX
            onMovedYChanged: window.y += movedY
        }
        Item{
            id:container
            anchors.fill: parent
            anchors.topMargin: 30
        }
    }

    function open(){
        show()
    }
}