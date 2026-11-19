// Vitrea OS default desktop: macOS-style top bar + floating, centred dock.
var wallpaper = "file:///usr/share/wallpapers/Vitrea/";

desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", wallpaper);
});

function trySet(obj, key, value) { try { obj[key] = value; } catch (e) { print("skip " + key + ": " + e); } }

// ---------- Top bar ----------
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.6);
trySet(top, "floating", false);
trySet(top, "opacity", "translucent");

var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "vitrea-logo");
menu.writeConfig("favoritesDisplay", 0);

top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("showSeconds", "Never");

// ---------- Dock ----------
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
trySet(dock, "floating", true);
trySet(dock, "lengthMode", "fit");
trySet(dock, "alignment", "center");
trySet(dock, "hiding", "none");
trySet(dock, "opacity", "translucent");

var launchers = [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox.desktop",
    "applications:org.kde.discover.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:systemsettings.desktop"
];
if (applicationExists("vitrea-install.desktop")) {
    launchers.unshift("applications:vitrea-install.desktop");
}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers.join(","));
tasks.writeConfig("iconSpacing", 2);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
