#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#include <QObject>
#include <QUrl>

class QFile;
class QFtp;
#include "decodemanager.h"
class ImageManager : public QObject
{
    Q_OBJECT
public:
    explicit ImageManager(QObject *parent = nullptr);

signals:
    void imagesCommandResult(int cmd ,int state ,int result);

public slots:
    void imagesCmdStart(int cmd, QString ,QStringList fileList = QStringList());
    void imagesCmd(QStringList);
    void imagesCmdEnd(int cmd ,int result);

    void init();
private slots:
    void ftpCommandFinished(int, bool error);

private:
    void ftpStart(const QString&);
    void ftpUpload(const QString&);
    void ftpEnd();
    void cmdResult(int cmd ,int result);

    void saveToFileStart(const QString& fileName);
    void saveToFileEnd(const QString& fileName);
    bool saveToFile(const QStringList& ,const QString&);

    void toEmail(const QString& para);
    void toApplication(const QString& para,const QStringList& fileList);

    void toPrint(const QStringList& ,const QString&);

    void cloudStart(const QString&);
    void toCloud(const QStringList& ,const QString&);

    void separationScanDecode(const QStringList&);
    void separationScanDecodeEnd();

    void decodeScanStart(const QString& fileName);
    void decodeScanDecode(const QStringList&);
    void decodeScanEnd();
private:
    struct Private_data{
        int id;
        QFile* file;
    };

    struct Separation_data{
        QString barcodeString;
        QStringList fileList;
    };

private:
    QFtp* ftp;
    int cmd;
    int cmd_status;
    int cmd_state;
    int currentPage;
    int result;
    DecodeManager* decodeManager;
    QString cmd_para;
    QStringList fileList;
    QUrl ftpUrl;
    QList<struct Private_data> ftp_data;
    QList<struct Separation_data> separation_data;
    QList<struct DMDecodeResult> decode_data;
};

#endif // IMAGEMANAGER_H