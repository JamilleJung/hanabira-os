// SPDX-License-Identifier: MIT
#include "shellbackend.h"

#include <QCommandLineParser>
#include <QDBusConnection>
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QPainter>
#include <QQmlContext>
#include <QQuickImageProvider>
#include <QQuickView>
#include <QRegularExpression>
#include <QScreen>
#include <QTimer>
#include <QDebug>
#include <cstdio>
#ifdef HANABIRA_HAVE_LAYER_SHELL
#include <LayerShellQt/Shell>
#include <LayerShellQt/Window>
#endif

class ThemeIconProvider final : public QQuickImageProvider {
public:
    ThemeIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requested) override {
        const int side = qBound(16, requested.width() > 0 ? requested.width() : 48, 256);
        const QString iconId = id.section(QLatin1Char('?'), 0, 0);
        QIcon icon = QIcon::fromTheme(iconId);
        if (icon.isNull() && iconId.startsWith(QLatin1Char('/'))) icon = QIcon(iconId);
        QPixmap result = icon.isNull() ? QPixmap() : icon.pixmap(side, side);
        if (result.isNull()) {
            result = QPixmap(side, side);
            result.fill(Qt::transparent);
            QPainter painter(&result);
            painter.setRenderHint(QPainter::Antialiasing);
            painter.setBrush(QColor(QStringLiteral("#D985A8")));
            painter.setPen(Qt::NoPen);
            painter.drawRoundedRect(result.rect().adjusted(2, 2, -2, -2), side / 4.0, side / 4.0);
        }
        if (size) *size = result.size();
        return result;
    }
};

struct ScreenViews {
    QString name;
    QQuickView *wallpaper = nullptr;
    QQuickView *panel = nullptr;
    QQuickView *dock = nullptr;
    QQuickView *launcher = nullptr;
    QQuickView *quick = nullptr;
    void close() {
        for (QQuickView *view : {wallpaper, panel, dock, launcher, quick}) {
            view->close();
            view->deleteLater();
        }
    }
};

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("hanabira-shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("hanabira"));
    QGuiApplication::setQuitOnLastWindowClosed(false);

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Hanabira Desktop shell"));
    parser.addHelpOption();
    parser.addOption({QStringLiteral("preview"), QStringLiteral("Open the actual shell UI in one development window")});
    parser.addOption({QStringLiteral("preview-launcher"), QStringLiteral("Show the launcher in preview and capture mode")});
    parser.addOption({QStringLiteral("preview-quick-settings"), QStringLiteral("Show quick settings in preview and capture mode")});
    parser.addOption({QStringLiteral("preview-query"), QStringLiteral("Fill launcher search in preview and capture mode"), QStringLiteral("query")});
    parser.addOption({QStringLiteral("preview-size"), QStringLiteral("Preview viewport, for example 800x600"), QStringLiteral("widthxheight")});
    parser.addOption({QStringLiteral("theme"), QStringLiteral("Apply one of dream, midnight, celestial"), QStringLiteral("name")});
    parser.addOption({QStringLiteral("self-test"), QStringLiteral("Check local application discovery and shell state")});
    parser.addOption({QStringLiteral("launch-desktop"), QStringLiteral("Launch one installed desktop entry and exit"), QStringLiteral("desktop-id")});
    parser.addOption({QStringLiteral("search-apps"), QStringLiteral("Print matching desktop entry IDs and exit"), QStringLiteral("query")});
    parser.addOption({QStringLiteral("capture"), QStringLiteral("Capture the preview window to a PNG and exit"), QStringLiteral("file")});
    parser.process(app);

    const bool preview = parser.isSet(QStringLiteral("preview")) || parser.isSet(QStringLiteral("capture"));
#ifndef HANABIRA_HAVE_LAYER_SHELL
    if (!preview && !parser.isSet(QStringLiteral("self-test")) && !parser.isSet(QStringLiteral("launch-desktop")) && !parser.isSet(QStringLiteral("search-apps"))) {
        qCritical() << "hanabira-shell requires a LayerShellQt build for a real Wayland session";
        return 2;
    }
#endif
    if (!preview && !parser.isSet(QStringLiteral("self-test")) && !parser.isSet(QStringLiteral("launch-desktop")) && !parser.isSet(QStringLiteral("search-apps")) && qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        qCritical() << "hanabira-shell needs a Wayland compositor";
        return 2;
    }

    const QString iconDir = qEnvironmentVariable("HANABIRA_ICON_DIR");
    if (!iconDir.isEmpty()) QIcon::setThemeSearchPaths(QStringList{iconDir} + QIcon::themeSearchPaths());

    ShellBackend shell;
    if (parser.isSet(QStringLiteral("theme"))) shell.setTheme(parser.value(QStringLiteral("theme")));
    if (parser.isSet(QStringLiteral("search-apps"))) {
        shell.apps()->setQuery(parser.value(QStringLiteral("search-apps")));
        for (int row = 0; row < shell.apps()->rowCount(); ++row)
            fprintf(stdout, "%s\n", qPrintable(shell.apps()->data(shell.apps()->index(row, 0), AppModel::IdRole).toString()));
        return 0;
    }
    if (parser.isSet(QStringLiteral("launch-desktop")))
        return shell.launchDesktopId(parser.value(QStringLiteral("launch-desktop"))) ? 0 : 1;
    if (parser.isSet(QStringLiteral("self-test"))) {
        const bool pass = shell.apps()->rowCount() > 0 &&
                          (shell.theme() == QLatin1String("dream") || shell.theme() == QLatin1String("midnight") || shell.theme() == QLatin1String("celestial"));
        qInfo() << "HDE self-test" << (pass ? "PASS" : "FAIL") << "applications=" << shell.apps()->rowCount()
                << "theme=" << shell.theme();
        return pass ? 0 : 1;
    }

    if (preview) {
        auto *view = new QQuickView;
        view->engine()->addImageProvider(QStringLiteral("hde-icon"), new ThemeIconProvider);
        view->rootContext()->setContextProperty(QStringLiteral("shell"), &shell);
        view->rootContext()->setContextProperty(QStringLiteral("screenName"), QStringLiteral("preview"));
        view->rootContext()->setContextProperty(QStringLiteral("primaryScreen"), true);
        view->rootContext()->setContextProperty(QStringLiteral("previewLauncher"), parser.isSet(QStringLiteral("preview-launcher")));
        view->rootContext()->setContextProperty(QStringLiteral("previewQuickSettings"), parser.isSet(QStringLiteral("preview-quick-settings")));
        view->rootContext()->setContextProperty(QStringLiteral("previewQuery"), parser.value(QStringLiteral("preview-query")));
        view->setResizeMode(QQuickView::SizeRootObjectToView);
        QSize previewSize(1280, 800);
        if (parser.isSet(QStringLiteral("preview-size"))) {
            const auto match = QRegularExpression(QStringLiteral("^(\\d+)x(\\d+)$"))
                                   .match(parser.value(QStringLiteral("preview-size")));
            if (!match.hasMatch()) { qCritical() << "Invalid preview size"; return 3; }
            previewSize.setWidth(qBound(320, match.captured(1).toInt(), 7680));
            previewSize.setHeight(qBound(320, match.captured(2).toInt(), 4320));
        }
        view->setWidth(previewSize.width());
        view->setHeight(previewSize.height());
        view->setSource(QUrl(QStringLiteral("qrc:/qml/Preview.qml")));
        if (view->status() == QQuickView::Error) return 3;
        view->show();
        if (parser.isSet(QStringLiteral("capture"))) {
            const QString output = parser.value(QStringLiteral("capture"));
            QTimer::singleShot(1400, view, [view, output] {
                const bool ok = view->grabWindow().save(output);
                qInfo() << (ok ? "Captured" : "Capture failed") << output;
                QCoreApplication::exit(ok ? 0 : 4);
            });
        }
        return app.exec();
    }

#ifdef HANABIRA_HAVE_LAYER_SHELL
    LayerShellQt::Shell::useLayerShell();
    if (!QDBusConnection::sessionBus().registerService(QStringLiteral("org.hanabira.Shell"))) {
        qCritical() << "A Hanabira shell instance is already running or the session bus is unavailable";
        return 5;
    }
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Shell"), &shell,
                                                  QDBusConnection::ExportAllSlots);

    QHash<QScreen *, ScreenViews *> screenViews;
    auto createView = [&](QScreen *screen, const QString &screenName, const QString &qml,
                          int width, int height, LayerShellQt::Window::Layer layer,
                          LayerShellQt::Window::Anchors anchors, int zone,
                          LayerShellQt::Window::KeyboardInteractivity keyboard) -> QQuickView * {
        auto *view = new QQuickView;
        view->setScreen(screen);
        view->setColor(Qt::transparent);
        view->setFlags(Qt::FramelessWindowHint);
        view->setResizeMode(QQuickView::SizeRootObjectToView);
        view->setWidth(width);
        view->setHeight(height);
        view->engine()->addImageProvider(QStringLiteral("hde-icon"), new ThemeIconProvider);
        view->rootContext()->setContextProperty(QStringLiteral("shell"), &shell);
        view->rootContext()->setContextProperty(QStringLiteral("screenName"), screenName);
        view->rootContext()->setContextProperty(QStringLiteral("primaryScreen"), screen == QGuiApplication::primaryScreen());
        view->rootContext()->setContextProperty(QStringLiteral("previewQuery"), QString());
        auto *surface = LayerShellQt::Window::get(view);
        surface->setLayer(layer);
        surface->setAnchors(anchors);
        surface->setExclusiveZone(zone);
        surface->setKeyboardInteractivity(keyboard);
        surface->setScope(QStringLiteral("hanabira-") + qml.toLower());
        view->setSource(QUrl(QStringLiteral("qrc:/qml/") + qml + QStringLiteral(".qml")));
        if (view->status() == QQuickView::Error) qWarning() << "Could not load" << qml;
        return view;
    };

    auto addScreen = [&](QScreen *screen) {
        if (screenViews.contains(screen)) return;
        auto *views = new ScreenViews;
        views->name = screen->name().isEmpty() ? QString::number(screenViews.size()) : screen->name();
        const QSize size = screen->geometry().size();
        const auto all = LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop |
                         LayerShellQt::Window::AnchorBottom | LayerShellQt::Window::AnchorLeft |
                         LayerShellQt::Window::AnchorRight);
        const auto top = LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop |
                         LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight);
        views->wallpaper = createView(screen, views->name, QStringLiteral("Wallpaper"), size.width(), size.height(),
            LayerShellQt::Window::LayerBackground, all, -1, LayerShellQt::Window::KeyboardInteractivityNone);
        views->panel = createView(screen, views->name, QStringLiteral("Panel"), size.width(), 54,
            LayerShellQt::Window::LayerTop, top, 54, LayerShellQt::Window::KeyboardInteractivityNone);
        views->dock = createView(screen, views->name, QStringLiteral("Dock"), qMin(570, int(size.width() * 0.82)), 82,
            LayerShellQt::Window::LayerTop, LayerShellQt::Window::AnchorBottom, 82,
            LayerShellQt::Window::KeyboardInteractivityNone);
        views->launcher = createView(screen, views->name, QStringLiteral("Launcher"), size.width(), size.height(),
            LayerShellQt::Window::LayerOverlay, all, -1, LayerShellQt::Window::KeyboardInteractivityExclusive);
        views->quick = createView(screen, views->name, QStringLiteral("QuickSettings"), size.width(), size.height(),
            LayerShellQt::Window::LayerOverlay, all, -1, LayerShellQt::Window::KeyboardInteractivityExclusive);
        screenViews.insert(screen, views);
        views->wallpaper->show();
        views->panel->show();
        views->dock->show();
        QObject::connect(screen, &QScreen::geometryChanged, &app, [&, screen](const QRect &geometry) {
            ScreenViews *current = screenViews.value(screen, nullptr);
            if (!current) return;
            for (QQuickView *view : {current->wallpaper, current->launcher, current->quick}) {
                view->setWidth(geometry.width());
                view->setHeight(geometry.height());
            }
            current->panel->setWidth(geometry.width());
            current->dock->setWidth(qMin(570, int(geometry.width() * 0.82)));
        });
    };

    for (QScreen *screen : QGuiApplication::screens()) addScreen(screen);
    QObject::connect(&app, &QGuiApplication::screenAdded, &app, addScreen);
    QObject::connect(&app, &QGuiApplication::screenRemoved, &app, [&](QScreen *screen) {
        if (auto *views = screenViews.take(screen)) { views->close(); delete views; }
    });
    QObject::connect(&app, &QGuiApplication::primaryScreenChanged, &app, [&](QScreen *primary) {
        for (auto it = screenViews.cbegin(); it != screenViews.cend(); ++it)
            it.value()->wallpaper->rootContext()->setContextProperty(QStringLiteral("primaryScreen"), it.key() == primary);
    });

    auto viewForName = [&](const QString &name) -> ScreenViews * {
        if (name.isEmpty()) return screenViews.value(QGuiApplication::primaryScreen(), nullptr);
        for (ScreenViews *views : screenViews) if (views->name == name) return views;
        return screenViews.value(QGuiApplication::primaryScreen(), nullptr);
    };
    QObject::connect(&shell, &ShellBackend::launcherRequested, &app,
                     [&](const QString &screenName, bool visible) {
        if (auto *views = viewForName(screenName)) {
            if (visible) { views->launcher->show(); views->launcher->requestActivate(); }
            else views->launcher->hide();
        }
    });
    QObject::connect(&shell, &ShellBackend::quickSettingsRequested, &app,
                     [&](const QString &screenName, bool visible) {
        if (auto *views = viewForName(screenName)) {
            if (visible) { views->quick->show(); views->quick->requestActivate(); }
            else views->quick->hide();
        }
    });
    return app.exec();
#endif
}
