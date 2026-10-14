// SPDX-License-Identifier: MIT
#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QSettings>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

typedef struct _GAppInfo GAppInfo;

class AppModel final : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)

public:
    enum Role { IdRole = Qt::UserRole + 1, NameRole, DescriptionRole, IconRole, CategoryRole };
    explicit AppModel(QObject *parent = nullptr);
    ~AppModel() override;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString query() const { return m_query; }
    QString category() const { return m_category; }
    void setQuery(const QString &query);
    void setCategory(const QString &category);
    Q_INVOKABLE bool launchAt(int row);
    Q_INVOKABLE bool launchId(const QString &desktopId);
    Q_INVOKABLE bool containsId(const QString &desktopId) const;
    Q_INVOKABLE QVariantMap appInfo(const QString &desktopId) const;
    void reload();

signals:
    void queryChanged();
    void categoryChanged();
    void launched(const QString &desktopId);
    void launchFailed(const QString &message);

private:
    struct App {
        GAppInfo *info = nullptr;
        QString id;
        QString name;
        QString description;
        QString icon;
        QString categories;
    };
    QVector<App> m_apps;
    QVector<int> m_visible;
    QString m_query;
    QString m_category = QStringLiteral("All");
    QStringList m_recent;
    QFileSystemWatcher m_watcher;
    void rebuildFilter();
    bool launch(const App &app);
    int indexOfId(const QString &desktopId) const;
};

class DesktopModel final : public QAbstractListModel {
    Q_OBJECT
public:
    enum Role { NameRole = Qt::UserRole + 1, IconRole, PathRole };
    explicit DesktopModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE bool openAt(int row);
    void reload();
signals:
    void openFailed(const QString &message);
private:
    struct Entry { QString name; QString icon; QString path; };
    QVector<Entry> m_entries;
    QFileSystemWatcher m_watcher;
};

class ShellBackend final : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.hanabira.Shell")
    Q_PROPERTY(AppModel *apps READ apps CONSTANT)
    Q_PROPERTY(DesktopModel *desktop READ desktop CONSTANT)
    Q_PROPERTY(QString theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(QString wallpaperUrl READ wallpaperUrl NOTIFY themeChanged)
    Q_PROPERTY(QVariantList dockApps READ dockApps NOTIFY dockAppsChanged)
    Q_PROPERTY(bool volumeAvailable READ volumeAvailable NOTIFY volumeChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted NOTIFY volumeChanged)
    Q_PROPERTY(bool batteryAvailable READ batteryAvailable NOTIFY batteryChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY batteryChanged)
    Q_PROPERTY(bool mediaAvailable READ mediaAvailable NOTIFY mediaChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaChanged)
    Q_PROPERTY(QString mediaArtist READ mediaArtist NOTIFY mediaChanged)
    Q_PROPERTY(QString mediaArtUrl READ mediaArtUrl NOTIFY mediaChanged)
    Q_PROPERTY(bool mediaPlaying READ mediaPlaying NOTIFY mediaChanged)
    Q_PROPERTY(bool mediaCanNext READ mediaCanNext NOTIFY mediaChanged)
    Q_PROPERTY(bool mediaCanPrevious READ mediaCanPrevious NOTIFY mediaChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit ShellBackend(QObject *parent = nullptr);
    AppModel *apps() { return &m_apps; }
    DesktopModel *desktop() { return &m_desktop; }
    QString theme() const { return m_theme; }
    QString wallpaperUrl() const;
    QVariantList dockApps() const { return m_dockApps; }
    bool volumeAvailable() const { return m_volumeAvailable; }
    int volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    bool batteryAvailable() const { return m_batteryAvailable; }
    int batteryPercent() const { return m_batteryPercent; }
    QString batteryStatus() const { return m_batteryStatus; }
    bool mediaAvailable() const { return !m_mediaService.isEmpty(); }
    QString mediaTitle() const { return m_mediaTitle; }
    QString mediaArtist() const { return m_mediaArtist; }
    QString mediaArtUrl() const { return m_mediaArtUrl; }
    bool mediaPlaying() const { return m_mediaPlaying; }
    bool mediaCanNext() const { return m_mediaCanNext; }
    bool mediaCanPrevious() const { return m_mediaCanPrevious; }
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE void setTheme(const QString &theme);
    Q_INVOKABLE bool launchDesktopId(const QString &desktopId);
    Q_INVOKABLE bool launchResult(int row);
    Q_INVOKABLE void toggleLauncherForScreen(const QString &screenName);
    Q_INVOKABLE void toggleQuickSettingsForScreen(const QString &screenName);
    Q_INVOKABLE void hidePopups();
    Q_INVOKABLE void setVolume(int value);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void mediaPlayPause();
    Q_INVOKABLE void mediaNext();
    Q_INVOKABLE void mediaPrevious();
    Q_INVOKABLE void clearError();

public slots:
    Q_SCRIPTABLE void ToggleLauncher();
    Q_SCRIPTABLE void ShowLauncher();
    Q_SCRIPTABLE void HideLauncher();

signals:
    void themeChanged();
    void dockAppsChanged();
    void volumeChanged();
    void batteryChanged();
    void mediaChanged();
    void lastErrorChanged();
    void launcherRequested(const QString &screenName, bool visible);
    void quickSettingsRequested(const QString &screenName, bool visible);

private:
    AppModel m_apps;
    DesktopModel m_desktop;
    QSettings m_settings;
    QString m_theme;
    QVariantList m_dockApps;
    QString m_launcherScreen;
    QString m_quickScreen;
    bool m_launcherVisible = false;
    bool m_quickVisible = false;
    bool m_volumeAvailable = false;
    int m_volume = 0;
    bool m_muted = false;
    bool m_batteryAvailable = false;
    int m_batteryPercent = 0;
    QString m_batteryStatus;
    QString m_lastError;
    QTimer m_volumeTimer;
    QTimer m_batteryTimer;
    QTimer m_mediaTimer;
    QString m_mediaService;
    QString m_mediaTitle;
    QString m_mediaArtist;
    QString m_mediaArtUrl;
    bool m_mediaPlaying = false;
    bool m_mediaCanNext = false;
    bool m_mediaCanPrevious = false;
    bool m_mediaRequestInFlight = false;
    void refreshDock();
    void refreshVolume();
    void refreshBattery();
    void refreshMedia();
    void mediaCommand(const QString &method);
    void reportError(const QString &message);
private slots:
    void onMediaSignal();
};
