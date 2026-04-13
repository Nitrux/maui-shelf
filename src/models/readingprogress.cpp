#include "readingprogress.h"

#include <QCryptographicHash>
#include <QSettings>

#include <MauiKit4/FileBrowsing/fmstatic.h>

ReadingProgress *ReadingProgress::m_instance = nullptr;

ReadingProgress::ReadingProgress(QObject *parent) : QObject(parent)
{
    QSettings settings;
    settings.beginGroup(QStringLiteral("ReadingProgress"));
    m_recentFiles = settings.value(QStringLiteral("RecentFiles")).toStringList();
    settings.endGroup();
}

ReadingProgress *ReadingProgress::instance()
{
    if (!m_instance)
        m_instance = new ReadingProgress();
    return m_instance;
}

QString ReadingProgress::encodeKey(const QString &url)
{
    return QString::fromLatin1(
        QCryptographicHash::hash(url.toUtf8(), QCryptographicHash::Md5).toHex());
}

void ReadingProgress::saveProgress(const QString &url, int page, int totalPages)
{
    const auto key = encodeKey(url);
    QSettings settings;
    settings.beginGroup(QStringLiteral("ReadingProgress"));
    settings.beginGroup(key);
    settings.setValue(QStringLiteral("url"), url);
    settings.setValue(QStringLiteral("page"), page);
    settings.setValue(QStringLiteral("totalPages"), totalPages);
    settings.endGroup();
    settings.endGroup();
}

int ReadingProgress::getProgress(const QString &url) const
{
    const auto key = encodeKey(url);
    QSettings settings;
    settings.beginGroup(QStringLiteral("ReadingProgress"));
    settings.beginGroup(key);
    const int page = settings.value(QStringLiteral("page"), 0).toInt();
    settings.endGroup();
    settings.endGroup();
    return page;
}

void ReadingProgress::markOpened(const QString &url)
{
    m_recentFiles.removeAll(url);
    m_recentFiles.prepend(url);
    while (m_recentFiles.size() > 10)
        m_recentFiles.removeLast();
    persist();
    Q_EMIT recentFilesChanged();
}

QVariantList ReadingProgress::recentFiles() const
{
    QVariantList result;
    for (const auto &url : m_recentFiles) {
        const QUrl qurl = QUrl::fromUserInput(url);
        if (!FMStatic::fileExists(qurl))
            continue;

        QVariantMap info = FMStatic::getFileInfo(qurl);

        // Ensure preview thumbnail is set for the image provider
        if (!info.contains(QStringLiteral("preview")) || info.value(QStringLiteral("preview")).toString().isEmpty())
            info.insert(QStringLiteral("preview"), QStringLiteral("image://preview/") + qurl.toString());

        // Inject reading progress keys
        const auto key = encodeKey(url);
        QSettings settings;
        settings.beginGroup(QStringLiteral("ReadingProgress"));
        settings.beginGroup(key);
        info.insert(QStringLiteral("page"), settings.value(QStringLiteral("page"), 0));
        info.insert(QStringLiteral("totalPages"), settings.value(QStringLiteral("totalPages"), 0));
        settings.endGroup();
        settings.endGroup();

        result << info;
    }
    return result;
}

void ReadingProgress::persist()
{
    QSettings settings;
    settings.beginGroup(QStringLiteral("ReadingProgress"));
    settings.setValue(QStringLiteral("RecentFiles"), m_recentFiles);
    settings.endGroup();
}
