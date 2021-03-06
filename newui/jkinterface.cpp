#include "jkinterface.h"
#include <QPrinterInfo>
#include <QQuickItem>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDir>
#include <QDateTime>

#include "../platform/devicemanager.h"
#include "ImageViewer/imagemodel.h"
#include "../imageManager/imagemanager.h"
using namespace JK;
#include "../platform/devicestruct.h"
#include "../newui/jkenums.h"
#include "../platform/platform.h"
#include "../platform/log.h"
JKInterface::JKInterface(QObject *parent)
    : QObject(parent)
    ,cmd_status(0)
{
    platform_init();
    deviceManager = new DeviceManager(this);
    deviceManager->moveToThread(&thread);
    connect(&thread ,SIGNAL(finished()) ,deviceManager ,SLOT(deleteLater()));

    connect(this ,SIGNAL(searchDeviceList()) ,deviceManager ,SLOT(searchDeviceList()));
    connect(this ,SIGNAL(connectDevice(int)) ,deviceManager ,SLOT(connectDevice(int)));
    connect(deviceManager ,SIGNAL(searchComplete()) ,this , SIGNAL(searchComplete()));
    connect(deviceManager ,&DeviceManager::updateDeviceList ,this ,&JKInterface::updateDeviceList);
    connect(deviceManager ,&DeviceManager::deviceConnected ,this ,&JKInterface::deviceConnected);
    connect(deviceManager ,&DeviceManager::updateDeviceStatus ,this ,&JKInterface::updateDeviceStatus);

    connect(this ,&JKInterface::cmdToDevice ,deviceManager ,&DeviceManager::cmdToDevice);
    connect(deviceManager ,&DeviceManager::cmdResult ,this , &JKInterface::deviceCmdResult);
    connect(deviceManager ,&DeviceManager::scanedImage ,this ,&JKInterface::scanedImage);
    connect(deviceManager ,&DeviceManager::progressChanged ,this ,&JKInterface::progressChanged);
    connect(this ,&JKInterface::init ,deviceManager ,&DeviceManager::init);

    imageManager = new ImageManager;
    imageManager->moveToThread(&thread_decode);
    connect(&thread_decode ,SIGNAL(finished()) ,imageManager ,SLOT(deleteLater()));
    connect(this ,&JKInterface::imagesCmd ,imageManager ,&ImageManager::imagesCmd);
    connect(this ,&JKInterface::imagesCmdStart ,imageManager ,&ImageManager::imagesCmdStart);
    connect(this ,&JKInterface::imagesCmdEnd ,imageManager ,&ImageManager::imagesCmdEnd);
    connect(imageManager ,&ImageManager::imagesCommandResult ,this ,&JKInterface::imagesCmdResult);
    connect(this ,&JKInterface::init ,imageManager ,&ImageManager::init);
    connect(this ,&JKInterface::cmdExtra ,imageManager ,&ImageManager::cmdExtra);
    connect(imageManager ,&ImageManager::cmdExtraResult ,this ,&JKInterface::cmdExtraResult);

    thread.start();
    thread_decode.start();
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
    QStringList sl;
    printerNameList = QStringList();
    foreach (QPrinterInfo pi, QPrinterInfo::availablePrinters()) {
//        qDebug()<<pi.printerName();
//        qDebug()<<pi.makeAndModel();
//        qDebug()<<pi.description();
        printerNameList << pi.printerName();
        sl << pi.description();
    }
    return sl;
//    return QPrinterInfo::availablePrinterNames();
}

void JKInterface::updateDeviceList(QStringList deviceList)
{
    if(!qobject_cast<QObject*>(scanData))
        return;
    scanData->setProperty("model_deviceList" ,deviceList);
}

void JKInterface::deviceConnected(QString currentDevice)
{
    if(!qobject_cast<QObject*>(scanData))
        return;
    scanData->setProperty("currentDevice" ,currentDevice);
    emit deviceConnectCompleted();
}

QString JKInterface::getCurrentDevice()
{
    if(!qobject_cast<QObject*>(scanData))
        return "";
    QString str = scanData->property("currentDevice").toString();
    return str;
}

void JKInterface::updateDeviceStatus(bool status)
{
    if(!qobject_cast<QObject*>(scanData))
        return;
    scanData->setProperty("deviceStatus" ,status);
}

void JKInterface::cmdComplete(int cmd,int result ,const QString& data)
{
    qDebug()<<"cmd complete data:"<<data;
    switch (cmd) {
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan_ToPrint:
    case DeviceStruct::CMD_QuickScan_ToFile:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToFTP:
    case DeviceStruct::CMD_QuickScan_ToCloud:
    case DeviceStruct::CMD_ScanTo_ToPrint:
    case DeviceStruct::CMD_ScanTo_ToFile:
    case DeviceStruct::CMD_ScanTo_ToEmail:
    case DeviceStruct::CMD_ScanTo_ToApplication:
    case DeviceStruct::CMD_ScanTo_ToCloud:
    case DeviceStruct::CMD_ScanTo_ToFTP:
    case DeviceStruct::CMD_ScanTo:
    case DeviceStruct::CMD_SCAN:
        if(!result || result == JKEnums::ImageCommandResult_NoError){
            if(imageModel->rowCount() == 0)
                result = DeviceStruct::ERR_scanImagesAreAllBlank;
        }
        break;
    default:
        break;
    }
    cmdResult(cmd ,result ,data);
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

    deviceManager->cancelScan(false);
    imageManager->cancel(false);
    switch (cmd) {
    //quick scan and decode sepearation check first.
    case DeviceStruct::CMD_QuickScan_ToFile:{
        QJsonObject jsonObj = QJsonDocument::fromJson(cmd_para.toLatin1()).object();
        QString filePath = jsonObj.value("filePath").toString();
        if(!QDir(filePath).exists()){
            cmdComplete(cmd ,JKEnums::ImageCommandResult_error_invalidFilePath);
            return;
        }
        QString fileName = jsonObj.value("fileName").toString();
        QString fullPath = filePath + "/" + fileName  + "_" + QDateTime::currentDateTime().toString("yyyyMMddHHmmss");
        int fileType = jsonObj.value("fileType").toInt(0);
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
    case DeviceStruct::CMD_QuickScan_ToPrint:
    {
        QJsonObject jsonObj = QJsonDocument::fromJson(cmd_para.toLatin1()).object();
        QString printerName = jsonObj.value("printerName").toString();
        foreach (QPrinterInfo pi, QPrinterInfo::availablePrinters()) {
            if(!printerName.compare(pi.description())){
                printerName = pi.printerName();
            }
        }
        QStringList printerList = QPrinterInfo::availablePrinterNames();
        if(printerList.isEmpty() || !printerList.contains(printerName)){
            cmdComplete(cmd ,JKEnums::ImageCommandResult_error_invalidPrinter);
            return;
        }
        QJsonObject obj{
            {"printerName",printerName}
        };
        sendImagesCommand(cmd ,QString(QJsonDocument(obj).toJson()));
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

    //scan to and device cmd just send cmd
    case DeviceStruct::CMD_ScanTo:
    default:
        emit cmdToDevice(cmd ,data);
        break;
    }
}

void JKInterface::deviceCmdResult(int cmd,int result ,QString data)
{
    Q_UNUSED(cmd);//it's device cmd
    switch (this->cmd) {//realy cmd
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan_ToPrint:
    case DeviceStruct::CMD_QuickScan_ToFile:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToFTP:
    case DeviceStruct::CMD_QuickScan_ToCloud:
        if(!result)
            result = imageCmdResult;
        emit signal_deviceCmdResult(this->cmd ,result ,data);
        emit imagesCmdEnd(this->cmd ,result);
        break;
    default:
        cmdComplete(this->cmd ,result ,data);
        break;
    }
}

void JKInterface::scanedImage(QString filename,QSize sourceSize)
{
    imageModel->addImage(ImageItem(filename ,sourceSize));

    switch (this->cmd) {
    case DeviceStruct::CMD_DecodeScan:
    case DeviceStruct::CMD_SeperationScan:
    case DeviceStruct::CMD_QuickScan_ToPrint:
    case DeviceStruct::CMD_QuickScan_ToFile:
    case DeviceStruct::CMD_QuickScan_ToEmail:
    case DeviceStruct::CMD_QuickScan_ToApplication:
    case DeviceStruct::CMD_QuickScan_ToCloud:
        if(imageCmdResult && imageCmdResult != JKEnums::ImageCommandResult_NoError)
            break;
        emit imagesCmd(QStringList()<<filename);
        break;
    case DeviceStruct::CMD_QuickScan_ToFTP:
        if(imageCmdResult && imageCmdResult != JKEnums::ImageCommandResult_NoError)
            break;
        //waiting for ftp login to processing
        if(cmd_state ==JKEnums::ImageCommandState_processing)
            emit imagesCmd(QStringList()<<filename);
        else
            fileList << filename;
        break;
    case DeviceStruct::CMD_ScanTo:
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
        if(!imageCmdResult || imageCmdResult == JKEnums::ImageCommandResult_NoError){
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
                cmd_state =  JKEnums::ImageCommandState_processing;
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
        case DeviceStruct::CMD_ScanTo_ToFTP:
            emit imagesCmdEnd(cmd ,result);
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
        cmdComplete(cmd ,result ,this->cmd_para);
        break;

    default:
        break;
    }
}

void JKInterface::cancelScan()
{
    deviceManager->cancelScan(true);
    imageManager->cancel(true);
}

void JKInterface::cancelSearch()
{
    deviceManager->cancelSearchDeviceList();
}

void JKInterface::cancelImageHandle()
{
    imageManager->cancel(true);
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
    fileList = imageModel->getFileList(selectedList);
    switch (cmd) {
    case DeviceStruct::CMD_ScanTo_ToPrint:{
        if(QPrinterInfo::availablePrinterNames().isEmpty()){
            cmdComplete(cmd ,JKEnums::ImageCommandResult_error_invalidPrinter);
            break;
        }
        QPrintDialog printDialog;
        if (printDialog.exec() == QDialog::Accepted){
            QPrinter* printer = printDialog.printer();

            QJsonObject obj{
                {"printerName",printer->printerName()}
            };
            sendImagesCommand(cmd ,QString(QJsonDocument(obj).toJson()) ,fileList);

        }
    }
        break;
    case DeviceStruct::CMD_ScanTo_ToFile:
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
    cmd_status = 1;
    imageCmdResult = JKEnums::ImageCommandResult_NoError;
    cmd_state = JKEnums::ImageCommandState_start;
    emit imagesCmdStart(cmd ,para ,fileList);
}

QString JKInterface::homeDictory()
{
    return QDir::home().absolutePath();
}

bool JKInterface::pathExist(const QString& filePath)
{
    return QDir(filePath).exists();
}

void JKInterface::showMinimize(QWindow* window)
{
    windowShowMinimize(window);
}

void JKInterface::setWindowFrameless(QWindow* window)
{
    windowSetWindowFrameless(window);
}

#include <QSysInfo>
int JKInterface::macVersion()
{
    int version = QSysInfo::macVersion();
    LOG_PARA("Version:%d" ,version);
    return version;
}

bool JKInterface::validate(const QValidator* validator ,QString& text)
{
    int pos;
    return validator->validate(text ,pos) != QValidator::Invalid;
}

#include <QHostAddress>
bool JKInterface::isSubmask(const QString& submask)
{
    QHostAddress address(submask);
    int ipv4 = address.toIPv4Address();
    if(ipv4 == 0)
        return true;
    int index = 0;
    for(;index < 32 ;index++){
        if(0 != (ipv4 & (0x80000000 >> index)))
            continue;
        else
            break;
    }
    if(index == 32)
        return false;
    for(;index < 32 ;index ++){
        if(0 == (ipv4 & (0x80000000 >> index)))
            continue;
        else
            break;
    }
    return index == 32;
}

bool JKInterface::isIpv4(const QString& ip)
{
    QHostAddress address(ip);
    int ipv4 = address.toIPv4Address();
    int val0 = (ipv4 >> 24);
    return val0 != 127 && val0 < 224;
}
