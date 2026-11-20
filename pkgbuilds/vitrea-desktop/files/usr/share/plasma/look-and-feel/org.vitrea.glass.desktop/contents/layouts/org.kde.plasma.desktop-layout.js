// Vitrea Liquid default desktop: slim glass top bar, floating glass dock, big clock + music widget.
var wallpaper = "file:///usr/share/wallpapers/VitreaDusk/";

desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", wallpaper);
});

function trySet(obj, key, value) { try { obj[key] = value; } catch (e) { print("skip " + key + ": " + e); } }

// ---------- Top bar: menu + workspaces | clock | tray ----------
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.7);
trySet(top, "floating", true);
trySet(top, "opacity", "translucent");

var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "vitrea-logo");
menu.writeConfig("favoritesDisplay", 0);

var pager = top.addWidget("org.kde.plasma.pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("displayedText", 0);          // workspace numbers
pager.writeConfig("showWindowOutlines", false);
pager.writeConfig("showWindowIcons", false);
pager.writeConfig("wrapPage", true);

top.addWidget("org.kde.plasma.panelspacer");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("showSeconds", 0);
clock.writeConfig("use24hFormat", 2);

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

// ---------- Dock ----------
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.0);
trySet(dock, "floating", true);
trySet(dock, "lengthMode", "fit");
trySet(dock, "alignment", "center");
trySet(dock, "hiding", "none");
trySet(dock, "opacity", "translucent");

// "Launchpad" opens KWin's Overview: all windows + app search (Plasma 6.8 has no dashboard widget)
var launchers = [
    "applications:vitrea-overview.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:firefox.desktop",
    "applications:org.kde.discover.desktop",
    "applications:org.kde.kate.desktop",
    "applications:systemsettings.desktop"
];
if (applicationExists("vitrea-install.desktop")) {
    launchers.unshift("applications:vitrea-install.desktop");
}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers.join(","));
tasks.writeConfig("iconSpacing", 1);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("indicateAudioStreams", true);

// ---------- Desktop widgets: big clock (right) + music player (bottom left) ----------
desktops().forEach(function (d) {
    var g = screenGeometry(d.screen);
    var cw = Math.round(g.width * 0.22), ch = Math.round(g.height * 0.40);
    var clockW = d.addWidget("org.vitrea.clock", g.width - cw - Math.round(g.width * 0.06), Math.round(g.height * 0.16), cw, ch);
    var mw = Math.round(g.width * 0.24), mh = Math.round(g.height * 0.17);
    var media = d.addWidget("org.kde.plasma.mediacontroller", Math.round(g.width * 0.03), g.height - mh - Math.round(g.height * 0.14), mw, mh);
});
