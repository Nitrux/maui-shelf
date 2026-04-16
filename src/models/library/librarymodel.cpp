#include "librarymodel.h"

#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QMimeDatabase>
#include <QTimer>
#include <QUrl>

#include <MauiKit4/FileBrowsing/fileloader.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>

#include <MauiKit4/Core/fmh.h>

#include "library.h"

static QStringList libraryFiltersForSource(const QString &source)
{
    QMimeDatabase mimedb;

    auto appendSuffixFilters = [](QStringList &filters, const QStringList &suffixes)
    {
        for (const auto &suffix : suffixes)
            filters << "*." + suffix;
    };

    QStringList filters;
    const QStringList pdfTypes = mimedb.mimeTypeForName("application/pdf").suffixes();
    QStringList comicTypes = mimedb.mimeTypeForName("application/vnd.comicbook+zip").suffixes();
    comicTypes << mimedb.mimeTypeForName("application/vnd.comicbook+rar").suffixes();

    if (source == "comics:///")
    {
        appendSuffixFilters(filters, comicTypes);
    }
    else if (source == "documents:///")
    {
        appendSuffixFilters(filters, pdfTypes);
    }
    else if (source == "epubs:///")
    {
        filters << "*.epub";
    }
    else
    {
        appendSuffixFilters(filters, pdfTypes);
        appendSuffixFilters(filters, comicTypes);
        filters << "*.epub";
        filters.removeDuplicates();
    }

    return filters;
}

static FMH::MODEL fileData(const QUrl &url)
{
    FMH::MODEL model = FMStatic::getFileInfoModel(url);

    QString thumbnail = model.value(FMH::MODEL_KEY::THUMBNAIL);
    const QString fileName = url.fileName().toLower();

    if (fileName.endsWith(QStringLiteral("cbr")) || fileName.endsWith(QStringLiteral("cbz")))
    {
        thumbnail = QStringLiteral("image://comiccover/") + url.toLocalFile();
    }
    else if (Library::instance()->isPDF(url.toString()))
    {
        thumbnail = QStringLiteral("image://pdfpreview/") + url.toString();
    }

    if (!thumbnail.isEmpty())
    {
        model.insert(FMH::MODEL_KEY::THUMBNAIL, thumbnail);
        model.insert(FMH::MODEL_KEY::PREVIEW, thumbnail);
    }

    return model;
}

LibraryModel::LibraryModel(QObject *parent)
    : MauiList(parent)
    , m_fileLoader(new FMH::FileLoader(this))
    , m_watcher(new QFileSystemWatcher(this))
    , m_rescanTimer(new QTimer(this))
    , m_sources({"collection:///"})
{
    qRegisterMetaType<LibraryModel *>("const LibraryModel*");

    m_rescanTimer->setSingleShot(true);
    m_rescanTimer->setInterval(250);

    connect(m_rescanTimer, &QTimer::timeout, this, &LibraryModel::rescan);

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &)
    {
        scheduleRescan();
    });

    connect(m_fileLoader, &FMH::FileLoader::itemsReady, this, [this](FMH::MODEL_LIST items)
    {
        Q_EMIT this->preItemsAppended(items.size());
        this->list << items;
        Q_EMIT this->postItemAppended();
        Q_EMIT this->countChanged();
    });

    connect(this, &LibraryModel::sourcesChanged, this, &LibraryModel::setList);

    connect(Library::instance(), &Library::sourcesChanged, this, [this](const QStringList &)
    {
        setList(m_sources);
    });
}

QStringList LibraryModel::resolvedSources(const QStringList &sources) const
{
    QStringList paths = sources;

    if (sources.count() == 1)
    {
        const QString source = sources.first();
        if (source == "comics:///" || source == "documents:///" || source == "epubs:///" || source == "collection:///")
        {
            paths = Library::instance()->sources();
        }
    }

    return paths;
}

void LibraryModel::refreshWatcher(const QStringList &paths)
{
    const auto watchedDirectories = m_watcher->directories();
    if (!watchedDirectories.isEmpty())
    {
        m_watcher->removePaths(watchedDirectories);
    }

    if (!m_autoScan)
    {
        return;
    }

    QStringList directories;

    for (const auto &entry : paths)
    {
        const auto url = QUrl::fromUserInput(entry);
        QString localPath = url.isLocalFile() ? url.toLocalFile() : entry;
        if (localPath.isEmpty())
        {
            continue;
        }

        QFileInfo info(localPath);
        if (!info.exists())
        {
            continue;
        }

        const QString rootPath = info.isDir() ? info.absoluteFilePath() : info.absolutePath();
        if (rootPath.isEmpty())
        {
            continue;
        }

        directories << rootPath;

        QDirIterator it(rootPath, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext())
        {
            directories << it.next();
        }
    }

    directories.removeDuplicates();

    if (!directories.isEmpty())
    {
        m_watcher->addPaths(directories);
    }
}

void LibraryModel::scheduleRescan()
{
    if (!m_autoScan)
    {
        return;
    }

    m_rescanTimer->start();
}

void LibraryModel::setList(const QStringList &sources)
{
    this->clear();
    const QStringList paths = resolvedSources(sources);
    const QString source = sources.count() == 1 ? sources.first() : QStringLiteral("collection:///");
    const QStringList filters = libraryFiltersForSource(source);

    qDebug() << "Using filters for the collection seeker" << filters << QUrl::fromStringList(paths);

    refreshWatcher(paths);

    this->m_fileLoader->informer = &fileData;
    this->m_fileLoader->requestPath(QUrl::fromStringList(paths), true, filters);
}

const FMH::MODEL_LIST &LibraryModel::items() const
{
    return this->list;
}

bool LibraryModel::remove(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    Q_EMIT this->preItemRemoved(index);
    this->list.remove(index);
    Q_EMIT this->postItemRemoved();

    return true;
}

bool LibraryModel::deleteAt(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    auto url = this->list.at(index).value(FMH::MODEL_KEY::URL);
    if (remove(index))
    {
        if (FMStatic::removeFiles({url}))
        {
            return true;
        }
    }

    return false;
}

bool LibraryModel::bookmark(const int &index, const int &)
{
    if (index >= this->list.size() || index < 0)
        return false;

    return false;
}

void LibraryModel::clear()
{
    if (this->list.isEmpty())
    {
        return;
    }

    Q_EMIT this->preListChanged();
    this->list.clear();
    Q_EMIT this->postListChanged();
    Q_EMIT this->countChanged();
}

void LibraryModel::rescan()
{
    this->setList(m_sources);
}

void LibraryModel::removeFiles(const QStringList &urls)
{
    for (const auto &url : urls)
    {
        for (int i = this->list.size() - 1; i >= 0; --i)
        {
            const auto itemUrl = this->list.at(i).value(FMH::MODEL_KEY::URL);
            if (itemUrl == url)
            {
                deleteAt(i);
            }
        }
    }
}

void LibraryModel::setSources(QStringList sources)
{
    if (m_sources == sources)
        return;

    m_sources = sources;
    Q_EMIT sourcesChanged(m_sources);
}

void LibraryModel::setAutoScan(bool autoScan)
{
    if (m_autoScan == autoScan)
        return;

    m_autoScan = autoScan;
    if (!m_autoScan)
    {
        m_rescanTimer->stop();
    }

    refreshWatcher(resolvedSources(m_sources));
    Q_EMIT autoScanChanged(m_autoScan);

    if (m_autoScan)
    {
        scheduleRescan();
    }
}

void LibraryModel::componentComplete()
{
    this->setList(m_sources);
}

QStringList LibraryModel::sources() const
{
    return m_sources;
}

void LibraryModel::resetSources()
{
    setSources({"collection:///"});
}

bool LibraryModel::autoScan() const
{
    return m_autoScan;
}
