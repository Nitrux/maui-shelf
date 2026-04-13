#pragma once

#include <QObject>
#include <QVariantList>

/**
 * @brief Singleton that persists per-file reading position and maintains
 *        a "recently opened" list used by the Continue Reading section.
 */
class ReadingProgress : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(ReadingProgress)
    Q_PROPERTY(QVariantList recentFiles READ recentFiles NOTIFY recentFilesChanged FINAL)

public:
    static ReadingProgress *instance();

    /**
     * @brief Returns the last-saved page for @p url, or 0 if never tracked.
     */
    Q_INVOKABLE int getProgress(const QString &url) const;

    /**
     * @brief Returns up to 10 recently opened files as a list of QVariantMap,
     *        each containing standard FMH file-info keys plus "page" and "totalPages".
     */
    QVariantList recentFiles() const;

public Q_SLOTS:
    /**
     * @brief Saves the current @p page (0-indexed) and @p totalPages for @p url.
     */
    void saveProgress(const QString &url, int page, int totalPages);

    /**
     * @brief Records that @p url was opened, bumping it to the top of recentFiles.
     */
    void markOpened(const QString &url);

Q_SIGNALS:
    void recentFilesChanged();

private:
    static ReadingProgress *m_instance;
    QStringList m_recentFiles;

    explicit ReadingProgress(QObject *parent = nullptr);
    void persist();
    static QString encodeKey(const QString &url);
};
