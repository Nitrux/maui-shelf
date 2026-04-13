#include <QCommandLineParser>
#include <QIcon>
#include <QPair>
#include <QSurfaceFormat>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedString>

#include <MauiKit4/Core/mauiapp.h>
#include <MauiKit4/Documents/moduleinfo.h>
#include <MauiKit4/FileBrowsing/moduleinfo.h>

#include "library.h"
#include "models/library/librarymodel.h"
#include "models/readingprogress.h"

#include "../shelf_version.h"

#define SHELF_URI "org.maui.shelf"

int main(int argc, char *argv[])
{
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Maui");
    app.setWindowIcon(QIcon(":/assets/shelf.svg"));

    KLocalizedString::setApplicationDomain("shelf");
    KAboutData about(QStringLiteral("shelf"),
                     QStringLiteral("Shelf"),
                     SHELF_VERSION_STRING,
                     i18n("Browse and view your documents."),
                     KAboutLicense::LGPL_V3,
                     APP_COPYRIGHT_NOTICE,
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.setHomepage("https://mauikit.org");
    about.setProductName("maui/shelf");
    about.setBugAddress("https://invent.kde.org/maui/shelf/-/issues");
    about.setOrganizationDomain(SHELF_URI);
    about.setProgramLogo(app.windowIcon());

    about.addCredit(i18n("Peruse Developers"));

    const auto FBData = MauiKitFileBrowsing::aboutData();
    about.addComponent(FBData.name(), MauiKitFileBrowsing::buildVersion(), FBData.version(), FBData.webAddress());

    const auto DData = MauiKitDocuments::aboutData();
    about.addComponent(DData.name(), MauiKitDocuments::buildVersion(), DData.version(), DData.webAddress());

    const auto PopplerData = MauiKitDocuments::aboutPoppler();
    about.addComponent(PopplerData.name(), "", PopplerData.version(), PopplerData.webAddress());

    KAboutData::setApplicationData(about);
    MauiApp::instance()->setIconName("qrc:/assets/shelf.svg");

    QCommandLineParser parser;

    about.setupCommandLine(&parser);
    parser.process(app);

    about.processCommandLine(&parser);
    const QStringList args = parser.positionalArguments();

    QPair<QString, QList<QUrl>> arguments;
    arguments.first = "collection";

    if (!args.isEmpty())
    {
        arguments.first = "viewer";
    }

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/app/maui/shelf/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, args](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);

            if (!args.isEmpty())
                Library::instance()->openFiles(args);
        },
        Qt::QueuedConnection);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.rootContext()->setContextProperty("globalQmlEngine", &engine);
    engine.rootContext()->setContextProperty("initModule", arguments.first);
    engine.rootContext()->setContextProperty("initData", QUrl::toStringList(arguments.second));

    qmlRegisterType<LibraryModel>(SHELF_URI, 1, 0, "LibraryList");
    qmlRegisterSingletonInstance<Library>(SHELF_URI, 1, 0, "Library", Library::instance());
    qmlRegisterSingletonInstance<ReadingProgress>(SHELF_URI, 1, 0, "ReadingProgress", ReadingProgress::instance());

    engine.load(url);

    return app.exec();
}
