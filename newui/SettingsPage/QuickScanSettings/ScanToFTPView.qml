import QtQuick 2.0
import "../../component"
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
                text: qsTr("Server Address:")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKTextInput {
                id: textInput1
                width: 250
                height: 30
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: item2
            width: parent.width
            height: 60

            JKText {
                id: text2
                text: qsTr("User Name:")
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

            }
        }
        Item {
            id: item3
            width: parent.width
            height: 60

            JKText {
                id: text3
                text: qsTr("Password:")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKTextInput {
                id: textInput3
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

            JKText {
                id: text4
                text: qsTr("Target Path:")
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }

            JKTextInput {
                id: textInput4
                width: 250
                height: 30
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }


    property var setting
    Component.onCompleted:{
        init()
    }

    function init(){
        textInput1.text = setting.serverAddress
        textInput2.text = setting.userName
        textInput3.text = setting.password
        textInput4.text = setting.targetPath
    }
    function ok(){
        setting.serverAddress = textInput1.text
        setting.userName = textInput2.text
        setting.password = textInput3.text
        setting.targetPath = textInput4.text
        if(setting.userName === ""){
            warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_Faroe_server_addr1")))
            return false
        }else if(!setting.serverAddress === ""){
            warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_Faroe_username1")))
            return false
        }else if(!setting.password === ""){
            warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_password1")))
            return false
        }else if(!setting.targetPath === ""){
            warningWithImage(qsTr("ResStr_could_not_be_empty").arg(qsTr("ResStr_targetPath1")))
            return false
        }else if(!setting.serverAddress.match(/ftp:\/\/[^\/\.]+$/i)){
            warningWithImage(qsTr("ResStr_specify_incorrect").arg(qsTr("ResStr_Faroe_server_addr1")))
            return false
        }else if(!setting.targetPath.match(/\/[^\/\.]$/i) && checkQuote(setting.targetPath)){
            warningWithImage(qsTr("ResStr_specify_incorrect").arg(qsTr("ResStr_targetPath1")))
            return false
        }
        return true
    }
    function checkQuote(str) {
        var items = ["\\", "?", "*"];
        str = str.toLowerCase();
        for (var i = 0; i < items.length; i++) {
            if (str.indexOf(items[i]) >= 0) {
                return true;
            }
        }
        return false;
    }
}