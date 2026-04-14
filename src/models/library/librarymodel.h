#pragma once

#include <QObject>

#include <MauiKit4/Core/fmh.h>
#include <MauiKit4/Core/mauilist.h>

class QFileSystemWatcher;
class QTimer;

namespace FMH
{
class FileLoader;
}

class LibraryModel : public MauiList
{
    Q_OBJECT
    Q_PROPERTY(QStringList sources READ sources WRITE setSources NOTIFY sourcesChanged RESET resetSources)
    Q_PROPERTY(bool autoScan READ autoScan WRITE setAutoScan NOTIFY autoScanChanged)

public:
    explicit LibraryModel(QObject *parent = nullptr);
    const FMH::MODEL_LIST &items() const override;
    void componentComplete() override final;

    QStringList sources() const;
    void resetSources();
    bool autoScan() const;

private:
    FMH::FileLoader *m_fileLoader;
    QFileSystemWatcher *m_watcher;
    QTimer *m_rescanTimer;
    FMH::MODEL_LIST list;
    QStringList m_sources;
    bool m_autoScan = true;

    void setList(const QStringList &sources);
    QStringList resolvedSources(const QStringList &sources) const;
    void refreshWatcher(const QStringList &paths);
    void scheduleRescan();

public Q_SLOTS:
    bool remove(const int &index);
    bool deleteAt(const int &index);
    bool bookmark(const int &index, const int &value);
    void clear();
    void rescan();
    void removeFiles(const QStringList &urls);
    void setSources(QStringList sources);
    void setAutoScan(bool autoScan);

Q_SIGNALS:
    void sourcesChanged(QStringList sources);
    void autoScanChanged(bool autoScan);
};
