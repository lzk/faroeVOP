#ifndef SCANNERAPI_H
#define SCANNERAPI_H
#include "scannerstruct.h"
namespace JK {
class DeviceIO;
class ScannerAPI
{
public:
    ScannerAPI();
    void install(DeviceIO* dio);

    int jobCreate();
    int jobEnd();
    int startScan();
    int stopScan();
    int setParameters(const SC_PAR_DATA_T& para);
    int getInfo(SC_INFO_DATA_T& sc_infodata);
    int readScan(int dup, int *ImgSize,char* buffer ,int size);
    int cancelScan();
    int nvramW(int address ,char* buffer ,int size);
    int nvramR(int address ,char* buffer ,int size);
    int adfCheck(SC_ADF_CHECK_STA_T& status);
    int getFwVersion(char* version ,int maxLength);
    int getStatus(SC_STATUS_DATA_T& status);
    int resetScan();

private:
    DeviceIO* dio;
    int JobID;
};

}
#endif // SCANNERAPI_H
