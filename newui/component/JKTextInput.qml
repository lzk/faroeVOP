import QtQuick 2.7
import QtQuick.Controls 2.2

FocusScope{
    property alias input: input
    property alias cursorPosition: input.cursorPosition
    property alias readOnly: input.readOnly
    property alias text: input.text
    property alias maximumLength: input.maximumLength
    property alias validator: input.validator
    property alias echoMode: input.echoMode
    property alias tooltip: tooltip
    Rectangle{
        anchors.fill: parent
        color: "white"
        radius: 5
        border.color: tooltip.visible ?"red":"gray"
    }
    TextInput {
        id:input
        clip: true
        width: parent.width - 10
        anchors.centerIn: parent
        focus: true
        selectByMouse: true
        font.family: "Verdana"
        font.pixelSize: 14
        horizontalAlignment:TextInput.AlignLeft
        onActiveFocusChanged: {
            if(!activeFocus){
                cursorPosition = 0
            }
        }
            onTextChanged: {
                if(!activeFocus){
                    cursorPosition = 0
    //                ensureVisible(0)
                }
            }
    }

    ToolTip{
        id:tooltip
        visible: input.activeFocus && text !== ""
        background: Rectangle{
            color: "#9adbc8"
        }
    }
}

//TextInput {
//    id:input
//    clip: true
//    focus: true
//    selectByMouse: true
//    font.family: "Verdana"
//    font.pixelSize: 14
//    horizontalAlignment:TextInput.AlignLeft
//    verticalAlignment: TextInput.AlignVCenter
//    onFocusChanged: {
//        console.log("focus changed" ,focus)
//        if(!focus){
//            cursorPosition = 0
////                ensureVisible(0)
//        }
//    }
//    onActiveFocusChanged: {
//        console.log("focus changed" ,focus)
//        if(!activeFocus){
//            cursorPosition = 0
//        }
//    }

//    onTextChanged: {
//        console.log("text changed" ,focus)
//        if(!focus){
//            cursorPosition = 0
////                ensureVisible(0)
//        }
//    }

//    Rectangle{
//        z:-1
//        anchors.fill: parent
//        color: "white"
//        border.color: "gray"

//    }
//}
