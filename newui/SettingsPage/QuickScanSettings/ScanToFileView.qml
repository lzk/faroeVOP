import QtQuick 2.0
import QtQuick.Dialogs 1.2
import "../../component"
import "../../ScanData.js" as JSData
Item {
    width: 477
    height: 309

    Column{
        anchors.fill: parent
        Item {
            id: item1
            width: parent.width
            height: 60

            JKText {
                id: text1
                text: qsTr("ResStr_DocScan_Save_File_Type")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKComboBox {
                id: comboBox
                width: 250
                height: 35
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                model: ["PDF" ,"TIFF" ,"JPG" ,"BMP"]
            }
        }
        Item {
            id: item2
            width: parent.width
            height: 60

            JKText {
                id: text2
                text: qsTr("ResStr_File_Name")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKTextInput {
                id: textInput2
                width: 250
                height: 30
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                maximumLength: 32
            }
        }
        Item {
            id: item3
            width: parent.width
            height: 60

            JKText {
                id: text3
                text: qsTr("ResStr_DocScan_File_Path")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKTextInput {
                id: textInput3
                readOnly: true
                width: 250
                height: 30
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: item4
            width: parent.width
            height: 60

            JKTextButton {
                id: button_browse
                text: qsTr("ResStr_DocScan_Browse")
                width: 100
                height: 30
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: fileDialog.open()
            }
        }
    }
    FileDialog {
        id: fileDialog
        title: qsTr("Save As")
//        folder: shortcuts.pictures
        folder: "file://" + textInput3.text//JSData.defaultFilePath()
        nameFilters: JSData.constFileDialogSaveFileType()
        selectFolder: true
        onAccepted: {
            textInput3.text = decodeURIComponent(fileUrl).replace("file:///" ,"/")
            textInput3.cursorPosition = 0
        }
    }


    property var setting
    Component.onCompleted:{
        init()
    }

    function init(){
        comboBox.currentIndex = setting.fileType
        textInput2.text = setting.fileName
        textInput2.cursorPosition = 0
        textInput3.text = setting.filePath === ""?jkInterface.homeDictory() + "/Pictures" :setting.filePath
//        textInput3.text.replace(/~/ ,jkInterface.homeDictory())
        textInput3.cursorPosition = 0
    }
    function ok(){
        var fileType = comboBox.currentIndex
        var fileName = textInput2.text
        var filePath = textInput3.text
        if(filePath === ""){
            if(fileName === ""){
                warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_File_Path_And_Name")))
                textInput2.forceActiveFocus()
//                textInput2.focus = true
            }else{
                warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_DocScan_File_Path1")))
                textInput3.forceActiveFocus()
//                textInput3.focus = true
            }
            return false
        }else if(fileName === ""){
            warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_File_Name1")))
            textInput2.forceActiveFocus()
//            textInput2.focus = true
            return false
//        }else if(!filePath.match(/^[^\\\?\*:<>|\"\(\)\[\]]*$/)){
////            if(!fileName.match(/^[0-9a-zA-Z\-_.]*$/)){
//            if(!fileName.match(/^[^\/\\\?\*:<>|\"\(\)\[\]]*$/)){
//                warningWithImage(qsTr("ResStr_Invalid_xxx").arg(qsTr("ResStr_File_Path_And_Name")))
//                textInput2.forceActiveFocus()
////                textInput2.focus = true
//            }else{
//                warningWithImage(qsTr("ResStr_Invalid_xxx!").arg(qsTr("ResStr_DocScan_File_Path1")))
//                textInput3.forceActiveFocus()
////                textInput3.focus = true
//            }
//            return false
        }else if(!fileName.match(/^[^\/\\\?\*:<>|\"\(\)\[\]]*$/)){
//        }else if(!fileName.match(/^[0-9a-zA-Z\-_.]*$/)){
            warningWithImage(qsTr("ResStr_Invalid_xxx").arg(qsTr("ResStr_File_Name1")))
            textInput2.forceActiveFocus()
//            textInput2.focus = true
            return false
        }
        setting.fileType = fileType
        setting.fileName = fileName
        setting.filePath = filePath
        return true
    }
}
