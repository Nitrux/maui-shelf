#include "library.h"

#include <QFile>
#include <QSettings>
#include <QTextStream>

#include <MauiKit4/FileBrowsing/fmstatic.h>

Library *Library::m_instance = nullptr;

Library::Library(QObject *parent) : QObject(parent)
{
    static const auto defaultSources = QStringList({FMStatic::DocumentsPath});

    QSettings settings;
    settings.beginGroup("Settings");
    m_sources = settings.value("Sources", defaultSources).toStringList();
    settings.endGroup();
}

Library *Library::instance()
{
    if(m_instance)
    {
        return m_instance;
    }

    m_instance = new Library();
    return m_instance;
}

QVariantList Library::sourcesModel() const
{
    QVariantList res;
    for (const auto &url : m_sources)
    {
        if(FMStatic::fileExists(url))
        {
            res << FMStatic::getFileInfo(url);
        }
    }

    return res;
}

QStringList Library::sources() const
{
    return m_sources;
}

void Library::openFiles(QStringList files)
{
    QList<QUrl> res;
    for (const auto &file : files)
    {
        const auto url = QUrl::fromUserInput(file);
        if (FMStatic::isDir(url))
            continue;

        if (isSupported(url.toString()))
            res << url;
    }

    Q_EMIT this->requestedFiles(res);
}

void Library::removeSource(const QString &url)
{
    m_sources.removeOne(url);

    QSettings settings;
    settings.beginGroup("Settings");
    settings.setValue("Sources", m_sources);
    settings.endGroup();

    Q_EMIT this->sourcesChanged(m_sources);
}

void Library::addSources(const QStringList &urls)
{
    m_sources << urls;
    m_sources.removeDuplicates();

    QSettings settings;
    settings.beginGroup("Settings");
    settings.setValue("Sources", m_sources);
    settings.endGroup();

    Q_EMIT this->sourcesChanged(m_sources);
}

bool Library::isPDF(const QString &url)
{
    return FMStatic::getMime(QUrl::fromUserInput(url)) == QStringLiteral("application/pdf");
}

bool Library::isPlainText(const QString &url)
{
    return FMStatic::checkFileType(FMStatic::FILTER_TYPE::TEXT, FMStatic::getMime(QUrl::fromUserInput(url)));
}

bool Library::isEpub(const QString &url)
{
    return QUrl::fromUserInput(url).toString().endsWith(QStringLiteral(".epub"), Qt::CaseInsensitive);
}

bool Library::isCommicBook(const QString &url)
{
    const auto mime = FMStatic::getMime(QUrl::fromUserInput(url));
    return mime == QStringLiteral("application/vnd.comicbook+zip") || mime == QStringLiteral("application/vnd.comicbook+rar");
}

bool Library::isSupported(const QString &url)
{
    return isPDF(url) || isPlainText(url) || isEpub(url) || isCommicBook(url);
}

QString Library::readTextFile(const QString &url) const
{
    const QUrl fileUrl = QUrl::fromUserInput(url);
    if (!fileUrl.isLocalFile())
        return {};

    QFile file(fileUrl.toLocalFile());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    QTextStream stream(&file);
    return stream.readAll();
}
