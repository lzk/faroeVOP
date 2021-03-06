import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import "component"
import "ScanPage"
import "ScanData.js" as JSData
import com.liteon.JKInterface 1.0

ScanPageLayout {
    id: root
    width: 750
    height: 533

    Row{
        parent: item_search
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.left: parent.left
        spacing: 5
        JKImageButton{
            id:button_search
            source_normal: scanData.deviceStatus ?"qrc:/Images/device_normal_blue.png" :"qrc:/Images/device_normal.png"
            source_press: scanData.deviceStatus ?"qrc:/Images/device_normal_blue.png" :"qrc:/Images/device_press.png"
            width: 38
            height: 38
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.StackView.view.push("SearchDevicePage.qml")
        }
        Text {
            text: scanData.deviceStatus ?scanData.currentDevice.match(/^usb+/i) ?"USB" :scanData.currentDevice :qsTr("ResStr_disconnet")
            anchors.verticalCenter: parent.verticalCenter
        }
    }

//    ListView{
//        id:listview
//        parent: item_quickscan
//        anchors.fill: parent
//        model: scanData.quickScanSettings
//        clip: true
//        orientation:Qt.Horizontal
//        snapMode: ListView.SnapOneItem
//        delegate:
//            QuickScanButton{
//            width: ListView.view.width
//            height: ListView.view.height
//                id:button_quickScan
//                mode: model.modelData.scanSetting.colorMode === 0 ?qsTr("ResStr_Color") :qsTr("ResStr_Grayscale")
//                dpi: model.modelData.scanSetting.dpi === 0 ?qsTr("300DPI") :qsTr("200DPI")
//                adf: model.modelData.scanSetting.adfMode === 0 ?qsTr("ResStr_DocScan_2side") :qsTr("ResStr_DocScan_1side")
//                name: model.modelData.name
//                source: scanData.getCurrentQuickScanSource(model.modelData.sid)
//            }
//    }
    property int currentIndex: 0
    property var currentQuickScanSetting:scanData.getQuickScanSetting(currentIndex)
    QuickScanButton{
        id:button_quickScan
        parent: item_quickscan
        anchors.fill: parent
        index: (currentIndex+1)
        sid:currentQuickScanSetting.sid
        adfMode:currentQuickScanSetting.scanSetting.adfMode
        colorMode: currentQuickScanSetting.scanSetting.colorMode
        dpi:currentQuickScanSetting.scanSetting.dpi
    }

    onVisibleChanged: {
        if(visible){
            //just update
            if(currentIndex > 0){
                currentIndex --
                currentIndex ++
            }else{
                currentIndex ++
                currentIndex --
            }
        }
    }

    JKImageButton{
        id:button_left
        parent: item_leftButton
        anchors.fill: parent
        source_disable: "qrc:/Images/left_disable.png"
        source_normal: "qrc:/Images/left_normal.png"
        source_press: "qrc:/Images/left_press.png"
        enabled: currentIndex > 0
        onClicked: {
            currentIndex --
        }
    }
    JKImageButton{
        id:button_right
        parent: item_rightButton
        anchors.fill: parent
        source_disable: "qrc:/Images/right_disable.png"
        source_normal: "qrc:/Images/right_normal.png"
        source_press: "qrc:/Images/right_press.png"
        enabled: currentIndex < scanData.quickScanSettings.length - 1
        onClicked: {
            currentIndex ++
        }
    }

    JKFunctionButton{
        id:button_decode
        parent: item_decode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:110
        height: 150
        source_disable: "qrc:/Images/Main_btn_decode.png"
        source_normal: "qrc:/Images/Main_btn_decode.png"
        source_press: "qrc:/Images/Main_btn_decode.png"
        jktext.text:qsTr("ResStr_DocScan_Decode")
    }
    JKFunctionButton{
        id:button_separation
        parent: item_separation
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:110
        height: 150
        source_disable: "qrc:/Images/main_btn_separation.png"
        source_normal: "qrc:/Images/main_btn_separation.png"
        source_press: "qrc:/Images/main_btn_separation.png"
        jktext.text:qsTr("ResStr_DocScan_Separation")
    }
    JKFunctionButton{
        id:button_scanto
        parent: item_scanto
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:110
        height: 150
        source_disable: "qrc:/Images/main_btn_scanto.png"
        source_normal: "qrc:/Images/main_btn_scanto.png"
        source_press: "qrc:/Images/main_btn_scanto.png"
        jktext.text:qsTr("ResStr_DocScan_ScanTo")
    }
    JKFunctionButton{
        id:button_settings
        parent: item_settings
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:110
        height: 150
        source_disable: "qrc:/Images/main_btn_settings.png"
        source_normal: "qrc:/Images/main_btn_settings.png"
        source_press: "qrc:/Images/main_btn_settings.png"
        jktext.text:qsTr("ResStr_Setting_Title")
    }

    Connections{
        target: button_scanto
        onClicked: scanTo()
    }

    Connections{
        target: button_settings
        onClicked: root.StackView.view.push("SettingsPage.qml")
    }

    Connections{
        target: button_decode
        onClicked: setScanCmd(DeviceStruct.CMD_DecodeScan ,scanData.decodeSetting)
    }
    Connections{
        target: button_separation
        onClicked: setScanCmd(DeviceStruct.CMD_SeperationScan ,scanData.separationSetting)
    }

    Connections{
        target: button_quickScan
        onClicked:{
            var cmd = DeviceStruct.CMD_QuickScan_ToPrint + scanData.constQuickScanSids.indexOf(currentQuickScanSetting.sid)
            setScanCmd(cmd ,currentQuickScanSetting)
        }
    }

    Connections{
        target: jkInterface
        onCmdResult:{
            switch(cmd){
            case DeviceStruct.CMD_ScanTo:
                switch(result){
                case DeviceStruct.ERR_ACK:
                    if(jkImageModel.count > 0)
                        root.StackView.view.push("ScanToPage.qml")
                    break;
                case DeviceStruct.ERR_SCAN_CANCEL:
                    jkImageModel.removeAll()
                    break;
                default:
                    break
                }
                break
            }
        }
    }
    function scanTo(){
        setScanCmd(DeviceStruct.CMD_ScanTo ,scanData.scanToParameter)
    }
}
