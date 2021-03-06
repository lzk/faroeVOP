import QtQuick 2.0
import "../../component"
import "../../ScanData.js" as JSData
import com.liteon.JKInterface 1.0
Item {
    id:root
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
                text: qsTr("ResStr_Cloud_Type")
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
                model: JSData.constCloudType()
            }
        }
        Column{
            width: parent.width
//            visible: comboBox.currentText !== cloudTypes.icloud
            Item {
                id: item2
                width: parent.width
                height: 60
                visible: comboBox.currentText !== cloudTypes.icloud

                JKText {
                    id: text2
                    text: qsTr("ResStr_Reset_Access")
                    font.bold: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                }

                JKTextButton {
                    id: button_reset
                    text: qsTr("ResStr_Reset")
                    width: 100
                    height: 35
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item{
                 id: item3
                 width: parent.width
                 height: 120
                 visible: comboBox.currentText === cloudTypes.evernote
                 Column{
                     anchors.fill: parent
                     Item {
                         id: item31
                         width: parent.width
                         height: 60

                         JKText {
                             id: text31
                             text: qsTr("ResStr_DocScan_Note_Title")
                             font.bold: true
                             anchors.left: parent.left
                             anchors.verticalCenter: parent.verticalCenter
                             font.pixelSize: 12
                         }

                         JKTextInput {
                             id: textInput31
                             width: 250
                             height: 30
                             anchors.right: parent.right
                             anchors.verticalCenter: parent.verticalCenter
                         }
                     }
                     Item {
                         id: item32
                         width: parent.width
                         height: 60

                         JKText {
                             id: text32
                             text: qsTr("ResStr_DocScan_Note_Content")
                             font.bold: true
                             anchors.left: parent.left
                             anchors.verticalCenter: parent.verticalCenter
                             font.pixelSize: 12
                         }

                         JKTextInput {
                             id: textInput32
                             width: 250
                             height: 30
                             anchors.right: parent.right
                             anchors.verticalCenter: parent.verticalCenter
                         }
                     }
                 }

             }
             Item{
                 id: item4
                 width: parent.width
                 height: 120
                 visible: !item3.visible
                 Column{
                     anchors.fill: parent
                     Item {
                         id: item41
                         width: parent.width
                         height: 60
                         visible: comboBox.currentText !== cloudTypes.icloud

                         JKText {
                             id: text41
                             text: qsTr("ResStr_DocScan_Default_Path")
                             font.bold: true
                             anchors.left: parent.left
                             anchors.verticalCenter: parent.verticalCenter
                             font.pixelSize: 12
                         }

                         JKTextInput {
                             id: textInput41
                             width: 250
                             height: 30
                             anchors.right: parent.right
                             anchors.verticalCenter: parent.verticalCenter
                         }
                     }
                     Item {
                         id: item42
                         width: parent.width
                         height: 60

                         JKTextButton {
                             id: button_browse
                             text: qsTr("ResStr_DocScan_Browse")
                             width: 100
                             height: 30
                             anchors.right: parent.right
                             anchors.verticalCenter: parent.verticalCenter
                         }
                     }
                 }
             }

        }
    }

    property var cloudTypes : JSData.supportCloudType()
    property var setting
    Component.onCompleted:{
        init()
    }

    function init(){
        comboBox.currentIndex = JSData.constCloudType().indexOf(setting.cloudTypeText)
        textInput31.text = setting.noteTitle
        textInput31.cursorPosition = 0
        textInput32.text = setting.noteContent
        textInput32.cursorPosition = 0
        var filePath = ""
        switch(setting.cloudTypeText){
        case cloudTypes.dropbox:
            filePath = setting.dropboxFilePath
            break
        case cloudTypes.onedrive:
            filePath = setting.oneDriveFilePath
            break
        default:
            break;
        }
        textInput41.text = filePath
        textInput41.cursorPosition = 0
    }
    function ok(){
        setting.cloudTypeText = comboBox.currentText
        setting.noteTitle = textInput31.text
        setting.noteContent = textInput32.text
        switch(comboBox.currentText){
        case cloudTypes.dropbox:
             setting.dropboxFilePath = textInput41.text
            break
        case cloudTypes.onedrive:
            setting.oneDriveFilePath = textInput41.text
            break
        default:
            break;
        }
        return true
    }

    Connections{
        target: button_browse
        onClicked:{
            var setting ={}
            setting.cloudTypeText = root.setting.cloudTypeText
            setting.filePath = textInput41.text
            setting.callback = accepted
            setting.okButtonText = qsTr("ResStr_OK")
            setCmdExtra(DeviceStruct.CMD_Cloud_getFileList ,setting)
        }
    }

    function accepted(setting){
        textInput41.text = setting.filePath
        textInput41.cursorPosition = 0
        setting.dialog.close()
    }

}
