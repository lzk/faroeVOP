#ifndef NETIO_H
#define NETIO_H

#include <QHostAddress>
#include "../lld/deviceio.h"
using namespace JK;
class QTcpSocket;
class NetIO: public NetDeviceIO
{
public:
    NetIO();
    ~NetIO();

    int type();
    int openPort(int port);
    int open(int para = 0);
    int close(void);
    int write(char *buffer, int bufsize);
    int read(char *buffer, int bufsize);
    int writeCommand(char *buffer, int bufsize);
    int readCommand(char *buffer, int bufsize);
    int resolveUrl(const char* url);
    bool isConnected();

private:
    QTcpSocket* tcpSocket;
    QHostAddress hostAddress;
};

#endif // NETIO_H
