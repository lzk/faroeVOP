import QtQuick 2.0
import QtQuick.Layouts 1.1
import "component" as Local
import "../component"
import com.liteon.JKInterface 1.0
import QtQuick.Controls 2.2

Item {
    id: root
    width: 495
    height: 460
    enabled: scanData.deviceStatus && wifiSetting.powerSupply !== JKEnums.PowerMode_usbBusPower
    opacity: enabled ?1 :0.3
    property var wifiSetting:{
        "enable":true
        ,"type":0
        ,"encryption":0
        ,"wepKeyId":0
        ,"channel":0
        ,"ssid":""
        ,"password":""
        ,"apList":[]
        ,"powerSupply":JKEnums.PowerMode_unknown
    }
    property var apSetting:{
        "ssid":""
        ,"encryption":0
    }

    ScrollView{
        id: scrollView
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
//        anchors.rightMargin: 20
        clip: true
        contentHeight: item.height

        Item{
            id:item
            width: scrollView.width - 15
            height: column4.height
            Column {
                id:column4
                x:5
                width: parent.width - 5
                Item {
                    id: item3
                    height: 56
                    width: parent.width

                    JKText {
                        id: text1
                        text: qsTr("WLAN")
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 16
                    }

                    Local.JKCheckBox {
                        id: checkbox
                        width: 45
                        height: 22
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            wifiSetting.enable = checked
                            listview.model = null
                            setSetterCmd(DeviceStruct.CMD_setWifi ,wifiSetting)
                        }
                        checked: false
                    }
                    Local.DividingLine{
                        height: 6
                        width: parent.width
                        anchors.bottom: parent.bottom
                    }
                }

                Item{
                    id:item_enable
                    visible: checkbox.checked
                    width: parent.width
                    height: column2.visible ?column2.height :pitem_manual.height

                    Local.WiFiManualSettingView{
                        id:pitem_manual
                        width: parent.width
                        height: scrollView.height - item3.height
                        visible: !column2.visible
                        onReturnClicked: column2.visible = true
                        onConnectClicked:
                            setSetterCmd(DeviceStruct.CMD_setWifi ,setting)
                    }

                    Column{
                        id:column2
                        width: parent.width
                        Item {
                            id: item2
                            height: 45
                            width: parent.width

                            JKTextButton{
                                width: 120
                                height: 35
                                text: qsTr("ResStr_Manual_Wi_Fi")
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                onClicked: {
                                    pitem_manual.textInput_password.text = wifiSetting.password
                                    pitem_manual.textInput_ssid.text = wifiSetting.ssid
                                    pitem_manual.textInput_ssid.cursorPosition = 0
                                    var encryption = wifiSetting.encryption % 5
                                    switch(encryption){
                                    case 0:
                                    case 1:
                                        pitem_manual.combox_index = encryption
                                        break;
                                    case 3:
                                    case 4:
                                        pitem_manual.combox_index = encryption - 1
                                        break;
                                    default:
                                        pitem_manual.combox_index = -1
                                        break
                                    }
                                    column2.visible = false
                                }
                            }
                        }

                        Item{
                            width: parent.width
                            height: column3.height

                            Rectangle{
                                anchors.fill: parent
                                anchors.margins: -1
                                color: "transparent"
                                border.color: "lightgray"
                                radius: 3
                            }

                            Column{
                                id:column3
                                width: parent.width
                                Item {
                                    id: item5
                                    height: 40
                                    width: parent.width
                                    JKText {
                                        id: text4
                                        x:5
                                        text: qsTr("ResStr_WLAN_Network")
                                        anchors.verticalCenter: parent.verticalCenter
                                        font.pixelSize: 14
                                    }

                                    JKImageButton{
                                        width: 17
                                        height: 17
                                        source_disable: "qrc:/Images/Refresh_Disable.png"
                                        source_normal: "qrc:/Images/Status_RefreshEnable.tif"
                                        source_press: "qrc:/Images/Status_RefreshEnable.tif"
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        onClicked: {
                                            listview.model = null
                                            setSetterCmd(DeviceStruct.CMD_getWifiInfo ,wifiSetting)
                                        }
                                    }
                                    Image{
                                        width: parent.width
                                        height: 2
                                        source: "qrc:/Images/GreenLine.png"
                                        anchors.bottom: parent.bottom
                                    }
                                }
                                ListView{
                                    id:listview
                                    snapMode:ListView.SnapOneItem
                                    interactive :false
                                    width: parent.width
                                    height: contentHeight

                                    model: wifiSetting.apList
                                    delegate:delegate_listview
                                }
                            }
                        }
                    }
                }

            }

        }

    }

Component{
    id:delegate_listview
    JKAbstractButton {
        id:delegate
        width: ListView.view.width
        height:column.height
        property bool displayDetail: false
        Column{
            id:column
            width: parent.width
            spacing: 2
            Item{
                width: parent.width
                height: 3
            }
            JKText{
                id:text_ssid
                x:10
                font.pixelSize: 15
                text:model.modelData.ssid
            }
            Item{
                width: parent.width
                height: 20
                JKText{
                    x:10
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                    text:getEncryptionString(model.modelData.encryption)

                }
                Image {
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: delegate.ListView.isCurrentItem ?!displayDetail :true
                    source:model.modelData.encryption > 127?"qrc:/Images/Signal_Connect.png"
                                                                 :"qrc:/Images/Signal_Enable.png"
                }
            }
            Item{
                id:detail
                width: parent.width
                height: column1.height
                visible: delegate.ListView.isCurrentItem ?displayDetail :false
                Column{
                    id:column1
                    width: parent.width
                    spacing: 2
                    Item{
                        width: parent.width
                        height: 30
                        enabled:model.modelData.encryption % 5 !== 0
                        opacity: enabled ?1 :0.3
                        JKText{
                            text: qsTr("ResStr_Password")
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                         JKTextInput{
                             id:textInput_password
                             width: parent.width - 100
                             height: 30
                             anchors.verticalCenter: parent.verticalCenter
                             anchors.right: parent.right
                             anchors.rightMargin: 5
                             echoMode:checkbox_input.checked ?TextInput.Normal :TextInput.Password
                             validator: RegExpValidator{
                                 regExp:  model.modelData.encryption % 5 === 1 ?/^(?:.{5}|.{13}|[0-9a-fA-F]{10}|[0-9a-fA-F]{26})$/
                                                                   :/^(?:.{8,63}|[0-9a-fA-F]{64})$/
                             }
                         }

                    }

                    CheckBox{
                        id:checkbox_input
                        text: qsTr("ResStr_Display_Password")
                        enabled:model.modelData.encryption % 5 !== 0
                        indicator: Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            x: checkbox_input.leftPadding
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 13
                            border.color: "lightgray"

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: "#21be2b"
                                visible: checkbox_input.checked
                                anchors.centerIn: parent
                            }
                        }
                    }
                    Row{
                        visible: model.modelData.encryption % 5 === 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 30
                        spacing: 2
                        RadioButton{
                            id:radio0
                            text: qsTr("Key1")
                            checked: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        RadioButton{
                            id:radio1
                            text: qsTr("Key2")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        RadioButton{
                            id:radio2
                            text: qsTr("Key3")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        RadioButton{
                            id:radio3
                            text: qsTr("Key4")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Item{
                        width: parent.width
                        height: 40
                        Item{
                            anchors.fill: parent
                            anchors.rightMargin: parent.width / 2
                            JKTextButton{
                                anchors.fill: parent
                                anchors.margins: 5
                                anchors.centerIn: parent
                                text: qsTr("ResStr_Cancel")
                                onClicked:
                                    displayDetail = false
                            }
                        }
                        Item{
                            anchors.fill: parent
                            anchors.leftMargin: parent.width / 2
                            JKTextButton{
                                anchors.fill: parent
                                anchors.margins: 5
                                anchors.centerIn: parent
                                text: qsTr("ResStr_Connect")
                                onClicked: {
                                    var encryption = model.modelData.encryption % 5
                                    switch(encryption){
                                    case 1:
                                        if(!textInput_password.text.match(/^(?:.{5}|.{13}|[0-9a-fA-F]{10}|[0-9a-fA-F]{26})$/)){
                                            warningWithImage(qsTr("ResStr_Msg_2"))
//                                            textInput_password.focus = true
                                            textInput_password.forceActiveFocus()
                                            return
                                        }
                                        break;
                                    case 3:
                                    case 4:
                                        if(!textInput_password.text.match(/^(?:.{8,63}|[0-9a-fA-F]{64})$/)){
                                            warningWithImage(qsTr("ResStr_Msg_3"))
//                                            textInput_password.focus = true
                                            textInput_password.forceActiveFocus()
                                            return
                                        }
                                        break;
                                    default:
                                        break
                                    }

                                    var setting = {}
                                    setting.enable = true
                                    setting.type = 0
                                    setting.channel = 0
                                    setting.ssid = text_ssid.text
                                    setting.password = textInput_password.text
                                    setting.encryption = encryption
                                    if(radio0.checked){
                                        setting.wepKeyId = 0
                                    }else if(radio1.checked){
                                        setting.wepKeyId = 1
                                    }else if(radio2.checked){
                                        setting.wepKeyId = 2
                                    }else if(radio3.checked){
                                        setting.wepKeyId = 3
                                    }
                                    setSetterCmd(DeviceStruct.CMD_setWifi ,setting)
                                }
                            }
                        }
                    }
                }
            }
            Image{
                width: parent.width
                height: 2
                source: "qrc:/Images/Line.png"
            }
        }
//        MouseArea{
//            anchors.fill: parent
//            onClicked:{
//                delegate.ListView.view.currentIndex = delegate.index
//                delegate.displayDetail = !delegate.displayDetail
//            }
//        }
        onClicked:{
            ListView.view.currentIndex = index
//            displayDetail = !displayDetail
            displayDetail = true
        }
    }
}

    Component.onCompleted: {
        setSetterCmd(DeviceStruct.CMD_getWifiInfo ,wifiSetting)
    }

    Connections{
        target: jkInterface
        onCmdResult:{
            switch(cmd){
            case DeviceStruct.CMD_getWifiInfo:
                if(!result){
                    wifiSetting = JSON.parse(data)
                    console.log(data)
                    listview.model = wifiSetting.apList
                    checkbox.checked = wifiSetting.enable
                }else{
                    checkbox.checked = false;
                }

                break;
            case DeviceStruct.CMD_setWifi:
                break
            }
        }
    }

    function getEncryptionString(encryption){
        var str;
        if(encryption > 127)
            return qsTr("ResStr_Connected")
        var _encryption = encryption % 5
        switch(_encryption){
        case 0:
            str = qsTr("ResStr_No_Security")
            break
        case 1:
            str = qsTr("ResStr_Protected_by_WEP")
            break
        case 4:
            str = qsTr("ResStr_Protected_by_Mixed_Mode_PSK")
            break
        case 3:
            str = qsTr("ResStr_Protected_by_WPA2")
            break
        default:
            str = ""
            break
        }
        return str;
    }

}
