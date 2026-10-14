// Hanabira's first-run desktop layout. Uses only Plasma's built-in applets.
// It runs when a user applies the Global Theme with desktop layout enabled.
var currentPanels = panels();
var hanabiraLayoutPresent = false;
for (var i = 0; i < currentPanels.length; ++i) {
    var widgets = currentPanels[i].widgets();
    for (var j = 0; j < widgets.length; ++j) {
        if (widgets[j].type === "org.kde.plasma.kickoff") {
            widgets[j].currentConfigGroup = ["General"];
            if (widgets[j].readConfig("icon", "") === "hanabira-launcher") {
                hanabiraLayoutPresent = true;
            }
        }
    }
}

if (!hanabiraLayoutPresent) {
    // Replace only panels. Desktop icons and user files remain untouched.
    for (var k = 0; k < currentPanels.length; ++k) {
        currentPanels[k].remove();
    }

    var top = new Panel;
    top.location = "top";
    top.height = 38;
    top.lengthMode = "fill";
    top.hiding = "none";

    var launcher = top.addWidget("org.kde.plasma.kickoff");
    launcher.currentConfigGroup = ["General"];
    launcher.writeConfig("icon", "hanabira-launcher");
    launcher.writeConfig("favorites", [
        "preferred://browser",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:systemsettings.desktop"
    ]);

    top.addWidget("org.kde.plasma.pager");
    top.addWidget("org.kde.plasma.panelspacer");
    top.addWidget("org.kde.plasma.mediacontroller");
    top.addWidget("org.kde.plasma.systemtray");

    var clock = top.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    clock.writeConfig("dateFormat", "custom");
    clock.writeConfig("customDateFormat", "ddd d MMM");
    clock.writeConfig("autoFontAndSize", false);
    clock.writeConfig("fontFamily", "Prompt");
    clock.writeConfig("fontWeight", 57);
    clock.writeConfig("fontSize", 10);

    var dock = new Panel;
    dock.location = "bottom";
    dock.height = 56;
    dock.alignment = "center";
    dock.lengthMode = "fit";
    dock.hiding = "none";

    var geometry = screenGeometry(dock.screen);
    if (geometry && geometry.width > 0) {
        dock.minimumLength = Math.min(380, Math.floor(geometry.width * 0.54));
        dock.maximumLength = Math.max(380, Math.floor(geometry.width * 0.78));
    }

    var tasks = dock.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", [
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:org.kde.discover.desktop",
        "applications:systemsettings.desktop"
    ]);

    dock.addWidget("org.kde.plasma.showdesktop");
}

// The wallpaper package has both light and dark artwork selected by Plasma.
var activityDesktops = desktopsForActivity(currentActivity());
for (var d = 0; d < activityDesktops.length; ++d) {
    activityDesktops[d].wallpaperPlugin = "org.kde.image";
    activityDesktops[d].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    activityDesktops[d].writeConfig("Image", "Hanabira");
}
