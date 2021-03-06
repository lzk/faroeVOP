#ifndef JKINTERFACE_H
#define JKINTERFACE_H

#include <QObject>
#include <QSize>
#include <QMutex>
#include <QThread>
#include <QImage>
#include <QValidator>
class DeviceManager;
class ImageModel;
class ImageManager;
class JKInterface : public QObject
{
    Q_OBJECT
public:
    explicit JKInterface(QObject *parent = nullptr);
    ~JKInterface();

public:
    QString getCurrentDevice();
    void installImageModel(ImageModel* imageModel){this->imageModel=imageModel;}
public:
    Q_INVOKABLE QStringList getPrinterName();
    Q_INVOKABLE void cancelScan();
    Q_INVOKABLE void cancelSearch();
    Q_INVOKABLE void cancelImageHandle();
    Q_INVOKABLE void setCmd(int cmd ,const QString& data=QString());
    Q_INVOKABLE void setScanToCmd(int cmd ,QList<int> ,const QString& jsonData=QString());

    Q_INVOKABLE bool pathExist(const QString& filePath);
    Q_INVOKABLE void setScanDataHandle(QObject* scanData);
    Q_INVOKABLE QString homeDictory();
    Q_INVOKABLE void showMinimize(QWindow*);
    Q_INVOKABLE void setWindowFrameless(QWindow*);
    Q_INVOKABLE int macVersion();
    Q_INVOKABLE bool validate(const QValidator* ,QString& text);
    Q_INVOKABLE bool isSubmask(const QString& submask);
    Q_INVOKABLE bool isIpv4(const QString& ip);
signals:
    void searchDeviceList();
    void searchComplete();
    void connectDevice(int);

    void cmdToDevice(int cmd ,QString data);
    void progressChanged(int progress ,int page);
    void cmdResult(int cmd,int result ,QString data=QString());
    void signal_deviceCmdResult(int cmd,int result ,QString data=QString());

    void imagesCmdStart(int cmd, QString data ,QStringList fileList = QStringList());
    void imagesCmd(QStringList fileList = QStringList());
    void imagesCmdEnd(int cmd ,int result);

    void cmdExtra(int cmd ,QString para);
    void cmdExtraResult(int cmd ,QString para);

    void init();
    void deviceConnectCompleted();

public slots:
    void imagesCmdResult(int ,int ,int);
    void deviceCmdResult(int cmd,int result ,QString data);
    void scanedImage(QString filename,QSize sourceSize);
    void updateDeviceList(QStringList);
    void deviceConnected(QString);
    void updateDeviceStatus(bool);

private:

private:
    QObject* scanData;
    DeviceManager* deviceManager;
    ImageManager* imageManager;
    ImageModel* imageModel;
    int cmd;
    int cmd_state;
    int cmd_status;
    QString cmd_para;
    int imageCmdResult;
    QStringList fileList;
    QStringList printerNameList;
    QMutex mutex;
    QThread thread;
    QThread thread_decode;

    void sendImagesCommand(int cmd, QString ,const QStringList& fileList = QStringList());
    void cmdComplete(int cmd,int result ,const QString& data=QString());
};

#endif // JKINTERFACE_H
