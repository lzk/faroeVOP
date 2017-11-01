#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
//#include "../thumbnailviewer/imageresponseprovider.h"
#include "jkinterface.h"
#include <QQuickView>
int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    qmlRegisterType<JKInterface>("com.liteon.JKInterface",1,0,"JKInterface");
    qmlRegisterType<ImageModel>("com.liteon.JKInterface",1,0,"ImageModel");

    JKInterface jki;

    QQmlApplicationEngine engine;
    QQmlContext* ctxt = engine.rootContext();
    ctxt->setContextProperty("jkInterface" ,&jki);
    engine.load(QUrl(QLatin1String("qrc:/faroeVOP/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
