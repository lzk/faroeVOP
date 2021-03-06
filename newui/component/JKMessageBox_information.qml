import QtQuick 2.0

JKDialog {
    id:root
    width: 600 + 20 //548 + 20
    height: 228 + 20
    signal accepted(string para)
    signal rejected()
    property alias message: messagebox.message
    property alias showImage: messagebox.showImage
    property string para

    toolbar{
        text.text: qsTr("ResStr_DocScan_Info")
        text.color: "black"
        color: "#FF67A1CF"
    }
    JKMessageBoxLayout{
        id:messagebox
        parent: container
        anchors.fill: parent

        Image{
            parent:messagebox.item_image
            source:"qrc:/Images/warning.png"
            anchors.fill: parent
            anchors.margins: 5
        }

//        message.text: qsTr("Do you want to delete the selected image?")

        Row {
            parent: messagebox.item_button
            width: 250
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.top: parent.top

            JKTextButton {
                id: button_yes
                width: 120
                height: 30
                text: qsTr("ResStr_Yes")
                anchors.verticalCenter: parent.verticalCenter
                onClicked:{
                    root.close()
                    root.accepted(para)
                }
            }

            JKTextButton {
                id: button_no
                width: 120
                height: 30
                text: qsTr("ResStr_No")
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    root.close()
                    root.rejected()
                }
            }
        }
    }

//    function openWithMessage(message){
//        messagebox.message.text = message
//        open()
//    }
}
