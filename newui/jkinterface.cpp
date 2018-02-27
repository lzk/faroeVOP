#include "jkinterface.h"
#include <QPrinterInfo>
#include <QQuickItem>
#include <QJsonDocument>
#include <QJsonObject>

#include "../platform/devicemanager.h"
#include "ImageViewer/imagemodel.h"
#include "../imageManager/imagemanager.h"
using namespace JK;
#include "../platform/devicestruct.h"
#include "../newui/jkenums.h"
#include "../platform/platform.h"
JKInterface::JKInterface(QObject *parent)
    : QObject(parent)
    ,cmd_status(0)
{
    platform_init();
    deviceManager = new DeviceManager(this);
    deviceManager->moveToThread(&thread);
    connect(&thread ,SIGNAL(finished()) ,deviceManager ,SLOT(deleteLater()));

    connect(this ,SIGNAL(searchDeviceList()) ,deviceManager ,SLOT(searchDeviceList()));
//    connect(this ,SIGNAL(cancelSearch()) ,deviceManager ,SLOT(cancelSearchDeviceList()));
    connect(this ,SIGNAL(connectDevice(int)) ,deviceManager ,SLOT(connectDevice(int)));
    connect(deviceManager ,SIGNAL(searchComplete()) ,this , SIGNAL(searchComplete()));
    connect(deviceManager ,&DeviceManager::updateDeviceList ,this ,&JKInterface::updateDeviceList);
    connect(deviceManager ,&DeviceManager::deviceConnected ,this ,&JKInterface::deviceConnected);
    connect(deviceManager ,&DeviceManager::updateDeviceStatus ,this ,&JKInterface::updateDeviceStatus);

    connect(this ,&JKInterface::cmdToDevice ,deviceManager ,&DeviceManager::cmdToDevice);
    connect(deviceManager ,&DeviceManager::cmdResult ,this , &JKInterface::deviceCmdResult);
    connect(deviceManager ,&DeviceManager::scanedImage ,this ,&JKInterface::scanedImage);
    connect(deviceManager ,&DeviceManager::progressChanged ,this ,&JKInterface::progressChanged);

    imageManager = new ImageManager;
    imageManager->moveToThread(&thread_decode);
    connect(&thread_decode ,SIGNAL(finished()) ,imageManager ,SLOT(deleteLater()));
    connect(this ,&JKInterface::imagesCmd ,imageManager ,&ImageManager::imagesCmd);
    connect(this ,&JKInterface::imagesCmdStart ,imageManager ,&ImageManager::imagesCmdStart);
    connect(this ,&JKInterface::imagesCmdEnd ,imageManager ,&ImageManager::imagesCmdEnd);
    connect(imageManager ,&ImageManager::imagesCommandResult ,this ,&JKInterface::imagesCmdResult);
    connect(this ,&JKInterface::init ,imageManager ,&ImageManager::init);

    thread.start();
    thread_decode.start();
    emit init();
}

JKInterface::~JKInterface()
{
    thread.quit();
    thread.wait();
    thread_decode.quit();
    thread_decode.wait();
    this->scanData = NULL;
}
void JKInterface::setScanDataHandle(QObject *scanData)
{
    this->scanData = scanData;
}

QStringList JKInterface::getPrinterName()
{
    return QPrinterInfo::availablePrinterNames();
}


void JKInterface::updateDeviceList(QStringList deviceList)
{
    scanData->setProperty("model_deviceList" ,deviceList);

}

void JKInterface::deviceConnected(QString currentDevice)
{
    scanData->setProperty("currentDevice" ,currentDevice);
    emit deviceConnectCompleted();
}

QString JKInterface::getCurrentDevice()
{
    QString str = scanData->property("currentDevice").toString();
    return str;
}

void JKInterface::updateDeviceStatus(bool status)
{
    scanData->setProperty("deviceStatus" ,status);
}

void JKInterface::cmdComplete(int cmd,int result ,const QString& data)
{
    emit cmdResult(cmd ,result ,data);
    cmd_status = 0;
}

void JKInterface::setCmd(int cmd ,const QString& data)
{
    if(cmd_status)
        return;
    cmd_status = 1;
    this->cmd = cmd;
    this->cmd_para = data;
    qDebug()<<"cmd:"<<this->cmd;
    qDebug()<<"cmd para"<<data;

    switch (cmd) {

    case DeviceStruct::CMD_QuickScan_ToFile:{
        QJsonObject jsonObj = QJsonDocument::fromJson(cmd_para.toLatin1()).object();
        int fileType = jsonObj.value("fileType").toInt(0);
        QString filePath = jsonObj.value("filePath").toString();
        QString fileName = jsonObj.value("fileName").toString();
        QString fullPath = filePath + "/" + fileName;
        switch (fileType) {
        case 0:     fullPath += ".pdf";    break;
        case 1:     fullPath += ".tif";    break;
        case 2:     fullPath += ".jpg";    break;
        case 3:     fullPath += ".bmp";    break;
        default:
            break;
        }
        sendImagesCommand(cmd ,fullPath);
    }
        break;
    case DeviceStruct::CMD_QuickScan_ToPrint:{
        QJsonObject jsonObj = QJsonDocument::fromJson(cmd_para.toLatin1()).object();
        QString printerName = jsonObj.value("printerName").toString();
        sendImagesCommand(cmd ,printerName);
    }
        break;
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToCloud:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToFTP:
        sendImagesCommand(cmd ,data);
        break;
    case DeviceStruct::CMD_SCAN:
    case DeviceStruct::CMD_ScanTo:
    default:
        emit cmdToDevice(cmd ,data);
        break;
    }
}

void JKInterface::deviceCmdResult(int cmd,int result ,QString data)
{
    Q_UNUSED(cmd);
    switch (this->cmd) {
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan_ToPrint:
    case DeviceStruct::CMD_QuickScan_ToFile:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToFTP:
    case DeviceStruct::CMD_QuickScan_ToCloud:
        emit imagesCmdEnd(this->cmd ,result);
        break;
    default:
        cmdComplete(this->cmd ,result ,data);
        break;
    }
}

void JKInterface::scanedImage(QString filename,QSize sourceSize)
{
    switch (this->cmd) {
    case DeviceStruct::CMD_ScanTo:
        imageModel->addImage(ImageItem(filename ,sourceSize));
        break;
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan_ToPrint:
    case DeviceStruct::CMD_QuickScan_ToFile:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToCloud:
        emit imagesCmd(QStringList()<<filename);
        break;
    case DeviceStruct::CMD_QuickScan_ToFTP:
        if(imageCmdResult != JKEnums::ImageCommandResult_NoError)
            break;
        if(cmd_state ==JKEnums::ImageCommandState_processing)
            emit imagesCmd(QStringList()<<filename);
        else
            fileList << filename;
        break;
    default:
        break;
    }
}

void JKInterface::imagesCmdResult(int cmd ,int state ,int result)
{
    cmd_state = state;
    imageCmdResult = result;
    switch (state) {
    case JKEnums::ImageCommandState_start:
        if(imageCmdResult == JKEnums::ImageCommandResult_NoError){
            switch (cmd) {
            case DeviceStruct::CMD_ScanTo_ToPrint:
            case DeviceStruct::CMD_ScanTo_ToFile:
            case DeviceStruct::CMD_ScanTo_ToEmail:
            case DeviceStruct::CMD_ScanTo_ToApplication:
            case DeviceStruct::CMD_ScanTo_ToCloud:
            case DeviceStruct::CMD_ScanTo_ToFTP:
                if(!fileList.isEmpty())
                    imagesCmd(fileList);
                break;
            case DeviceStruct::CMD_DecodeScan:
            case DeviceStruct::CMD_SeperationScan:
            case DeviceStruct::CMD_QuickScan_ToPrint:
            case DeviceStruct::CMD_QuickScan_ToFile:
            case DeviceStruct::CMD_QuickScan_ToEmail:
            case DeviceStruct::CMD_QuickScan_ToApplication:
            case DeviceStruct::CMD_QuickScan_ToCloud:
            case DeviceStruct::CMD_QuickScan_ToFTP:
            default:
                emit cmdToDevice(DeviceStruct::CMD_SCAN ,cmd_para);
                break;
            }
        }else{
            emit imagesCmdEnd(cmd ,result);
        }
        break;

    case JKEnums::ImageCommandState_processing:
        switch (cmd) {
        case DeviceStruct::CMD_ScanTo_ToPrint:
        case DeviceStruct::CMD_ScanTo_ToFile:
        case DeviceStruct::CMD_ScanTo_ToEmail:
        case DeviceStruct::CMD_ScanTo_ToApplication:
        case DeviceStruct::CMD_ScanTo_ToCloud:
            emit imagesCmdEnd(cmd ,result);
            break;
        case DeviceStruct::CMD_ScanTo_ToFTP:
            break;
        case DeviceStruct::CMD_DecodeScan:
        case DeviceStruct::CMD_SeperationScan:
        case DeviceStruct::CMD_QuickScan_ToPrint:
        case DeviceStruct::CMD_QuickScan_ToFile:
        case DeviceStruct::CMD_QuickScan_ToEmail:
        case DeviceStruct::CMD_QuickScan_ToApplication:
        case DeviceStruct::CMD_QuickScan_ToCloud:
        case DeviceStruct::CMD_QuickScan_ToFTP:
        default:
            // emit end from cmd result
//            emit imagesCmdEnd(cmd ,result);
            break;
        }
        break;

    case JKEnums::ImageCommandState_end:
        cmdComplete(cmd ,result);
        break;

    default:
        break;
    }
}

void JKInterface::cancelScan()
{
    deviceManager->cancelScan();
}

#include <QPrintDialog>
#include <QPrinter>
void JKInterface::setScanToCmd(int cmd ,QList<int> selectedList,const QString& jsonData)
{
    if(selectedList.length()<=0){
        return;
    }
    if(cmd_status)
        return;
    cmd_status = 1;
    fileList = imageModel->getFileList(selectedList);
    switch (cmd) {
    case DeviceStruct::CMD_ScanTo_ToPrint:{
        QPrintDialog printDialog;
        if (printDialog.exec() == QDialog::Accepted){
            sendImagesCommand(cmd ,printDialog.printer()->printerName() ,fileList);
        }
    }
        break;
    case DeviceStruct::CMD_ScanTo_ToFile:{
//        QString fileName = QUrl(jsonData).toLocalFile();
//        emit imagesCmdStart(cmd ,fileName);
//        emit imagesCmd(fileList);
//        emit imagesCmdEnd(cmd ,0);
//        break;
    }
    case DeviceStruct::CMD_ScanTo_ToEmail:
    case DeviceStruct::CMD_ScanTo_ToApplication:
    case DeviceStruct::CMD_ScanTo_ToFTP:
    case DeviceStruct::CMD_ScanTo_ToCloud:
        sendImagesCommand(cmd ,jsonData ,fileList);
        break;
    default:
        break;
    }
}

void JKInterface::sendImagesCommand(int cmd, QString para ,const QStringList& fileList)
{
    this->fileList = fileList;
    imageCmdResult = JKEnums::ImageCommandResult_NoError;
    cmd_state = JKEnums::ImageCommandState_start;
    emit imagesCmdStart(cmd ,para ,fileList);
}
void JKInterface::test()
{
    qDebug()<<"test";
    QPrintDialog printDialog;
    if (printDialog.exec() == QDialog::Accepted){

    }
}