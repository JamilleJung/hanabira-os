// SPDX-License-Identifier: MIT
#include "shellbackend.h"

#include <QDesktopServices>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#ifdef signals
#undef signals
#endif
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>
#include <algorithm>
#include <unistd.h>

namespace {
QString textOrEmpty(const char *text) { return text ? QString::fromUtf8(text) : QString(); }

QString iconName(GIcon *icon) {
    if (!icon) return QStringLiteral("application-x-executable");
    if (G_IS_THEMED_ICON(icon)) {
        const char *const *names = g_themed_icon_get_names(G_THEMED_ICON(icon));
        if (names && names[0]) return QString::fromUtf8(names[0]);
    }
    if (G_IS_FILE_ICON(icon)) {
        GFile *file = g_file_icon_get_file(G_FILE_ICON(icon));
        char *path = g_file_get_path(file);
        const QString result = textOrEmpty(path);
        g_free(path);
        return result;
    }
    char *name = g_icon_to_string(icon);
    const QString result = textOrEmpty(name);
    g_free(name);
    return result;
}

QString readFile(const QString &path) {
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()).trimmed() : QString();
}

QVariantMap dbusMap(QVariant value) {
    if (value.metaType() == QMetaType::fromType<QDBusVariant>())
        value = value.value<QDBusVariant>().variant();
    if (value.metaType() == QMetaType::fromType<QDBusArgument>())
        return qdbus_cast<QVariantMap>(value.value<QDBusArgument>());
    return value.toMap();
}
}

AppModel::AppModel(QObject *parent) : QAbstractListModel(parent) {
    QSettings settings(QStringLiteral("hanabira"), QStringLiteral("shell"));
    m_recent = settings.value(QStringLiteral("recent")).toStringList();
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { reload(); });
    reload();
}

AppModel::~AppModel() {
    for (const App &app : m_apps) g_object_unref(app.info);
}

int AppModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_visible.size(); }

QVariant AppModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size()) return {};
    const App &app = m_apps.at(m_visible.at(index.row()));
    switch (role) {
    case IdRole: return app.id;
    case NameRole: return app.name;
    case DescriptionRole: return app.description;
    case IconRole: return app.icon;
    case CategoryRole: return app.categories;
    default: return {};
    }
}

QHash<int, QByteArray> AppModel::roleNames() const {
    return {{IdRole, "desktopId"}, {NameRole, "name"}, {DescriptionRole, "description"},
            {IconRole, "iconName"}, {CategoryRole, "categories"}};
}

void AppModel::reload() {
    beginResetModel();
    for (const App &app : m_apps) g_object_unref(app.info);
    m_apps.clear();

    GList *all = g_app_info_get_all();
    for (GList *item = all; item; item = item->next) {
        auto *info = G_APP_INFO(item->data);
        if (!g_app_info_should_show(info) || !g_app_info_get_id(info)) {
            g_object_unref(info);
            continue;
        }
        App app;
        app.info = info; // Own the reference returned by g_app_info_get_all().
        app.id = textOrEmpty(g_app_info_get_id(info));
        app.name = textOrEmpty(g_app_info_get_display_name(info));
        app.description = textOrEmpty(g_app_info_get_description(info));
        app.icon = iconName(g_app_info_get_icon(info));
        if (G_IS_DESKTOP_APP_INFO(info))
            app.categories = textOrEmpty(g_desktop_app_info_get_categories(G_DESKTOP_APP_INFO(info)));
        if (!app.name.isEmpty()) m_apps.append(std::move(app));
        else g_object_unref(info);
    }
    g_list_free(all);
    std::sort(m_apps.begin(), m_apps.end(), [](const App &a, const App &b) {
        return QString::localeAwareCompare(a.name, b.name) < 0;
    });
    rebuildFilter();
    endResetModel();

    const QStringList paths = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &path : paths) {
        if (QDir(path).exists() && !m_watcher.directories().contains(path)) m_watcher.addPath(path);
    }
}

void AppModel::setQuery(const QString &query) {
    if (m_query == query) return;
    m_query = query;
    beginResetModel();
    rebuildFilter();
    endResetModel();
    emit queryChanged();
}

void AppModel::setCategory(const QString &category) {
    if (m_category == category) return;
    m_category = category;
    beginResetModel();
    rebuildFilter();
    endResetModel();
    emit categoryChanged();
}

void AppModel::rebuildFilter() {
    struct Match { int index; int score; };
    QVector<Match> matches;
    const QString needle = m_query.trimmed().toCaseFolded();
    for (int i = 0; i < m_apps.size(); ++i) {
        const App &app = m_apps.at(i);
        if (m_category != QLatin1String("All") && !app.categories.contains(m_category, Qt::CaseInsensitive)) continue;
        int score = 1000;
        if (!needle.isEmpty()) {
            const QString name = app.name.toCaseFolded();
            const QString desc = app.description.toCaseFolded();
            if (name.startsWith(needle)) score = 0;
            else if (name.contains(QLatin1Char(' ') + needle)) score = 10;
            else if (name.contains(needle)) score = 20;
            else if (desc.contains(needle)) score = 60;
            else {
                int cursor = 0;
                bool matched = true;
                for (const QChar c : needle) {
                    const int found = name.indexOf(c, cursor);
                    if (found < 0) { matched = false; break; }
                    cursor = found + 1;
                }
                if (matched) score = 80;
                else continue;
            }
        } else {
            const int recent = m_recent.indexOf(app.id);
            if (recent >= 0) score = recent;
        }
        matches.append({i, score});
    }
    std::stable_sort(matches.begin(), matches.end(), [](const Match &a, const Match &b) {
        return a.score < b.score;
    });
    m_visible.clear();
    for (const Match &match : matches) m_visible.append(match.index);
}

bool AppModel::launch(const App &app) {
    GError *error = nullptr;
    GAppLaunchContext *context = g_app_launch_context_new();
    const bool ok = g_app_info_launch(app.info, nullptr, context, &error);
    g_object_unref(context);
    if (!ok) {
        emit launchFailed(error ? QString::fromUtf8(error->message) : QStringLiteral("Application launch failed"));
        if (error) g_error_free(error);
        return false;
    }
    m_recent.removeAll(app.id);
    m_recent.prepend(app.id);
    while (m_recent.size() > 16) m_recent.removeLast();
    QSettings settings(QStringLiteral("hanabira"), QStringLiteral("shell"));
    settings.setValue(QStringLiteral("recent"), m_recent);
    emit launched(app.id);
    return true;
}

bool AppModel::launchAt(int row) {
    return row >= 0 && row < m_visible.size() && launch(m_apps.at(m_visible.at(row)));
}

int AppModel::indexOfId(const QString &id) const {
    for (int i = 0; i < m_apps.size(); ++i) if (m_apps.at(i).id == id) return i;
    return -1;
}

bool AppModel::launchId(const QString &id) {
    const int index = indexOfId(id);
    if (index < 0) {
        emit launchFailed(QStringLiteral("Application not installed: %1").arg(id));
        return false;
    }
    return launch(m_apps.at(index));
}

bool AppModel::containsId(const QString &id) const { return indexOfId(id) >= 0; }

QVariantMap AppModel::appInfo(const QString &id) const {
    const int index = indexOfId(id);
    if (index < 0) return {};
    const App &app = m_apps.at(index);
    return {{QStringLiteral("id"), app.id}, {QStringLiteral("name"), app.name},
            {QStringLiteral("icon"), app.icon}};
}

DesktopModel::DesktopModel(QObject *parent) : QAbstractListModel(parent) {
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { reload(); });
    reload();
}

int DesktopModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_entries.size(); }

QVariant DesktopModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size()) return {};
    const Entry &entry = m_entries.at(index.row());
    switch (role) {
    case NameRole: return entry.name;
    case IconRole: return entry.icon;
    case PathRole: return entry.path;
    default: return {};
    }
}

QHash<int, QByteArray> DesktopModel::roleNames() const {
    return {{NameRole, "name"}, {IconRole, "iconName"}, {PathRole, "filePath"}};
}

void DesktopModel::reload() {
    const QString dirPath = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    QDir dir(dirPath);
    beginResetModel();
    m_entries.clear();
    const QFileInfoList entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot,
                                                     QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
    for (const QFileInfo &file : entries) {
        Entry entry { file.completeBaseName(), QStringLiteral("text-x-generic"), file.absoluteFilePath() };
        if (file.isDir()) entry.icon = QStringLiteral("folder");
        else if (file.suffix() == QLatin1String("desktop")) {
            entry.icon = QStringLiteral("application-x-executable");
            GDesktopAppInfo *info = g_desktop_app_info_new_from_filename(file.absoluteFilePath().toUtf8().constData());
            if (info) {
                entry.name = textOrEmpty(g_app_info_get_display_name(G_APP_INFO(info)));
                entry.icon = iconName(g_app_info_get_icon(G_APP_INFO(info)));
                g_object_unref(info);
            }
        } else if (file.suffix().toLower() == QLatin1String("png") || file.suffix().toLower() == QLatin1String("jpg"))
            entry.icon = QStringLiteral("image-x-generic");
        m_entries.append(std::move(entry));
    }
    endResetModel();
    if (dir.exists() && !m_watcher.directories().contains(dirPath)) m_watcher.addPath(dirPath);
}

bool DesktopModel::openAt(int row) {
    if (row < 0 || row >= m_entries.size()) return false;
    const QString path = m_entries.at(row).path;
    const QFileInfo file(path);
    if (file.suffix() == QLatin1String("desktop")) {
        const bool trustedSystemLink = file.isSymLink() && file.symLinkTarget().startsWith(QLatin1String("/usr/share/applications/"));
        if ((!file.isExecutable() || file.ownerId() != geteuid()) && !trustedSystemLink) {
            emit openFailed(QStringLiteral("Mark this desktop shortcut executable before launching it."));
            return false;
        }
        GDesktopAppInfo *info = g_desktop_app_info_new_from_filename(path.toUtf8().constData());
        if (!info) {
            emit openFailed(QStringLiteral("Invalid desktop shortcut: %1").arg(file.fileName()));
            return false;
        }
        GError *error = nullptr;
        const bool ok = g_app_info_launch(G_APP_INFO(info), nullptr, nullptr, &error);
        g_object_unref(info);
        if (!ok) {
            emit openFailed(error ? QString::fromUtf8(error->message) : QStringLiteral("Shortcut launch failed"));
            if (error) g_error_free(error);
        }
        return ok;
    }
    const bool ok = QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    if (!ok) emit openFailed(QStringLiteral("No application can open %1").arg(file.fileName()));
    return ok;
}

ShellBackend::ShellBackend(QObject *parent)
    : QObject(parent), m_apps(this), m_desktop(this),
      m_settings(QSettings::IniFormat, QSettings::UserScope, QStringLiteral("hanabira"), QStringLiteral("shell")) {
    m_theme = m_settings.value(QStringLiteral("theme"), QStringLiteral("dream")).toString();
    if (m_theme != QLatin1String("dream") && m_theme != QLatin1String("midnight") && m_theme != QLatin1String("celestial"))
        m_theme = QStringLiteral("dream");
    setTheme(m_theme);
    connect(&m_apps, &AppModel::launchFailed, this, &ShellBackend::reportError);
    connect(&m_desktop, &DesktopModel::openFailed, this, &ShellBackend::reportError);
    connect(&m_apps, &AppModel::launched, this, [this] { hidePopups(); });
    refreshDock();
    connect(&m_volumeTimer, &QTimer::timeout, this, &ShellBackend::refreshVolume);
    m_volumeTimer.start(10000);
    refreshVolume();
    connect(&m_batteryTimer, &QTimer::timeout, this, &ShellBackend::refreshBattery);
    m_batteryTimer.start(30000);
    refreshBattery();
    connect(&m_mediaTimer, &QTimer::timeout, this, &ShellBackend::refreshMedia);
    m_mediaTimer.start(4000);
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/org/mpris/MediaPlayer2"),
                                          QStringLiteral("org.freedesktop.DBus.Properties"),
                                          QStringLiteral("PropertiesChanged"), this, SLOT(onMediaSignal()));
    QDBusConnection::sessionBus().connect(QStringLiteral("org.freedesktop.DBus"),
                                          QStringLiteral("/org/freedesktop/DBus"),
                                          QStringLiteral("org.freedesktop.DBus"),
                                          QStringLiteral("NameOwnerChanged"), this, SLOT(onMediaSignal()));
    refreshMedia();
}

QString ShellBackend::wallpaperUrl() const {
    if (m_theme == QLatin1String("celestial")) {
        const QString path = qEnvironmentVariable("HANABIRA_SHELL_ASSET_DIR", QStringLiteral("/usr/share/hanabira/shell"))
                             + QStringLiteral("/celestial-blue.png");
        return QFileInfo::exists(path) ? QUrl::fromLocalFile(path).toString() : QStringLiteral("qrc:/assets/celestial-blue.png");
    }
    const QString root = qEnvironmentVariable("HANABIRA_WALLPAPER_DIR", QStringLiteral("/usr/share/wallpapers/Hanabira/contents"));
    const QString path = m_theme == QLatin1String("midnight")
        ? root + QStringLiteral("/images_dark/1586x992.png")
        : root + QStringLiteral("/images/2560x1600.png");
    return QFileInfo::exists(path) ? QUrl::fromLocalFile(path).toString() : QStringLiteral("qrc:/assets/celestial-blue.png");
}

void ShellBackend::setTheme(const QString &theme) {
    if (theme != QLatin1String("dream") && theme != QLatin1String("midnight") && theme != QLatin1String("celestial")) return;
    m_theme = theme;
    m_settings.setValue(QStringLiteral("theme"), m_theme);
    QIcon::setThemeName(theme == QLatin1String("dream") ? QStringLiteral("HanabiraDay") : QStringLiteral("HanabiraNight"));
    emit themeChanged();
}

void ShellBackend::refreshDock() {
    QStringList saved;
    if (m_settings.contains(QStringLiteral("pinned"))) {
        saved = m_settings.value(QStringLiteral("pinned")).toStringList();
    } else {
        const QList<QStringList> defaults {
            {QStringLiteral("firefox-esr.desktop"), QStringLiteral("firefox.desktop"),
             QStringLiteral("com.google.Chrome.desktop")},
            {QStringLiteral("org.kde.dolphin.desktop"), QStringLiteral("org.gnome.Nautilus.desktop"),
             QStringLiteral("com.system76.CosmicFiles.desktop")},
            {QStringLiteral("org.kde.konsole.desktop"), QStringLiteral("Alacritty.desktop"),
             QStringLiteral("org.gnome.Terminal.desktop")},
            {QStringLiteral("org.kde.kate.desktop"), QStringLiteral("org.gnome.gedit.desktop"),
             QStringLiteral("com.system76.CosmicEdit.desktop")}
        };
        for (const QStringList &group : defaults) {
            for (const QString &id : group) {
                if (m_apps.containsId(id)) { saved.append(id); break; }
            }
        }
    }
    m_dockApps.clear();
    for (const QString &id : saved) {
        const QVariantMap info = m_apps.appInfo(id);
        if (!info.isEmpty()) m_dockApps.append(info);
    }
    emit dockAppsChanged();
}

bool ShellBackend::launchDesktopId(const QString &id) { return m_apps.launchId(id); }
bool ShellBackend::launchResult(int row) { return m_apps.launchAt(row); }

void ShellBackend::toggleLauncherForScreen(const QString &screenName) {
    if (m_quickVisible) {
        emit quickSettingsRequested(m_quickScreen, false);
        m_quickVisible = false;
    }
    if (m_launcherVisible && m_launcherScreen != screenName) emit launcherRequested(m_launcherScreen, false);
    const bool next = !m_launcherVisible || m_launcherScreen != screenName;
    m_launcherScreen = screenName;
    m_launcherVisible = next;
    emit launcherRequested(screenName, next);
}

void ShellBackend::toggleQuickSettingsForScreen(const QString &screenName) {
    if (m_launcherVisible) {
        emit launcherRequested(m_launcherScreen, false);
        m_launcherVisible = false;
    }
    if (m_quickVisible && m_quickScreen != screenName) emit quickSettingsRequested(m_quickScreen, false);
    const bool next = !m_quickVisible || m_quickScreen != screenName;
    m_quickScreen = screenName;
    m_quickVisible = next;
    emit quickSettingsRequested(screenName, next);
}

void ShellBackend::hidePopups() {
    if (m_launcherVisible) emit launcherRequested(m_launcherScreen, false);
    if (m_quickVisible) emit quickSettingsRequested(m_quickScreen, false);
    m_launcherVisible = false;
    m_quickVisible = false;
}

void ShellBackend::ToggleLauncher() { toggleLauncherForScreen(QString()); }
void ShellBackend::ShowLauncher() {
    if (!m_launcherVisible) toggleLauncherForScreen(QString());
}
void ShellBackend::HideLauncher() { hidePopups(); }

void ShellBackend::refreshVolume() {
    if (QStandardPaths::findExecutable(QStringLiteral("wpctl")).isEmpty()) {
        if (m_volumeAvailable) { m_volumeAvailable = false; emit volumeChanged(); }
        return;
    }
    auto *process = new QProcess(this);
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process](int code, QProcess::ExitStatus status) {
        if (status == QProcess::NormalExit && code == 0) {
            const QString result = QString::fromUtf8(process->readAllStandardOutput());
            const QRegularExpression number(QStringLiteral("([0-9]+(?:\\.[0-9]+)?)"));
            const auto match = number.match(result);
            if (match.hasMatch()) {
                const int volume = qBound(0, qRound(match.captured(1).toDouble() * 100.0), 150);
                const bool muted = result.contains(QStringLiteral("MUTED"), Qt::CaseInsensitive);
                if (!m_volumeAvailable || volume != m_volume || muted != m_muted) {
                    m_volumeAvailable = true; m_volume = volume; m_muted = muted; emit volumeChanged();
                }
            }
        }
        process->deleteLater();
    });
    process->start(QStringLiteral("wpctl"), {QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@")});
}

void ShellBackend::setVolume(int value) {
    if (!m_volumeAvailable) return;
    value = qBound(0, value, 100);
    auto *process = new QProcess(this);
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process](int code, QProcess::ExitStatus status) {
        if (status != QProcess::NormalExit || code != 0)
            reportError(QString::fromUtf8(process->readAllStandardError()).trimmed());
        process->deleteLater();
        refreshVolume();
    });
    process->start(QStringLiteral("wpctl"), {QStringLiteral("set-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), QString::number(value) + QLatin1Char('%')});
}

void ShellBackend::toggleMute() {
    if (!m_volumeAvailable) return;
    auto *process = new QProcess(this);
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process](int code, QProcess::ExitStatus status) {
        if (status != QProcess::NormalExit || code != 0)
            reportError(QString::fromUtf8(process->readAllStandardError()).trimmed());
        process->deleteLater();
        refreshVolume();
    });
    process->start(QStringLiteral("wpctl"), {QStringLiteral("set-mute"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), QStringLiteral("toggle")});
}

void ShellBackend::refreshBattery() {
    QDir dir(QStringLiteral("/sys/class/power_supply"));
    const QStringList batteries = dir.entryList({QStringLiteral("BAT*")}, QDir::Dirs | QDir::NoDotAndDotDot);
    const bool available = !batteries.isEmpty();
    int percent = 0;
    QString status;
    if (available) {
        percent = readFile(dir.filePath(batteries.first() + QStringLiteral("/capacity"))).toInt();
        status = readFile(dir.filePath(batteries.first() + QStringLiteral("/status")));
    }
    if (available != m_batteryAvailable || percent != m_batteryPercent || status != m_batteryStatus) {
        m_batteryAvailable = available; m_batteryPercent = percent; m_batteryStatus = status;
        emit batteryChanged();
    }
}

void ShellBackend::onMediaSignal() { refreshMedia(); }

void ShellBackend::refreshMedia() {
    if (m_mediaRequestInFlight) return;
    const auto *busInterface = QDBusConnection::sessionBus().interface();
    if (!busInterface) return;
    const QDBusReply<QStringList> response = busInterface->registeredServiceNames();
    if (!response.isValid()) return;
    QStringList players;
    for (const QString &name : response.value())
        if (name.startsWith(QLatin1String("org.mpris.MediaPlayer2."))) players.append(name);
    if (players.isEmpty()) {
        if (!m_mediaService.isEmpty()) {
            m_mediaService.clear(); m_mediaTitle.clear(); m_mediaArtist.clear(); m_mediaArtUrl.clear();
            m_mediaPlaying = false; m_mediaCanNext = false; m_mediaCanPrevious = false;
            emit mediaChanged();
        }
        return;
    }
    if (!players.contains(m_mediaService)) {
        m_mediaService = players.first();
        emit mediaChanged();
    }
    const QString service = m_mediaService;
    QDBusInterface properties(service, QStringLiteral("/org/mpris/MediaPlayer2"),
                              QStringLiteral("org.freedesktop.DBus.Properties"), QDBusConnection::sessionBus());
    m_mediaRequestInFlight = true;
    auto *watcher = new QDBusPendingCallWatcher(properties.asyncCall(QStringLiteral("GetAll"),
                           QStringLiteral("org.mpris.MediaPlayer2.Player")), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, service, watcher] {
        m_mediaRequestInFlight = false;
        QDBusPendingReply<QVariantMap> reply = *watcher;
        watcher->deleteLater();
        if (service != m_mediaService || reply.isError()) return;
        const QVariantMap properties = reply.value();
        const QVariantMap metadata = dbusMap(properties.value(QStringLiteral("Metadata")));
        m_mediaTitle = metadata.value(QStringLiteral("xesam:title")).toString();
        const QVariant artists = metadata.value(QStringLiteral("xesam:artist"));
        m_mediaArtist = artists.toStringList().join(QStringLiteral(", "));
        if (m_mediaArtist.isEmpty()) m_mediaArtist = artists.toString();
        m_mediaArtUrl = metadata.value(QStringLiteral("mpris:artUrl")).toString();
        m_mediaPlaying = properties.value(QStringLiteral("PlaybackStatus")).toString() == QLatin1String("Playing");
        m_mediaCanNext = properties.value(QStringLiteral("CanGoNext"), true).toBool();
        m_mediaCanPrevious = properties.value(QStringLiteral("CanGoPrevious"), true).toBool();
        emit mediaChanged();
    });
}

void ShellBackend::mediaCommand(const QString &method) {
    if (m_mediaService.isEmpty()) return;
    QDBusInterface player(m_mediaService, QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"), QDBusConnection::sessionBus());
    auto *watcher = new QDBusPendingCallWatcher(player.asyncCall(method), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher] {
        QDBusPendingReply<> reply = *watcher;
        if (reply.isError()) reportError(reply.error().message());
        watcher->deleteLater();
        refreshMedia();
    });
}

void ShellBackend::mediaPlayPause() { mediaCommand(QStringLiteral("PlayPause")); }
void ShellBackend::mediaNext() { if (m_mediaCanNext) mediaCommand(QStringLiteral("Next")); }
void ShellBackend::mediaPrevious() { if (m_mediaCanPrevious) mediaCommand(QStringLiteral("Previous")); }

void ShellBackend::reportError(const QString &message) {
    m_lastError = message.isEmpty() ? QStringLiteral("The action could not be completed") : message;
    emit lastErrorChanged();
}

void ShellBackend::clearError() {
    if (m_lastError.isEmpty()) return;
    m_lastError.clear();
    emit lastErrorChanged();
}
