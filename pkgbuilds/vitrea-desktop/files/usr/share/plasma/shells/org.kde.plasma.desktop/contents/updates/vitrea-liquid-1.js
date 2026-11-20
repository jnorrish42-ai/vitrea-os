// Vitrea "Liquid" update. Plasma runs each script in this folder once per user, at login, so
// people who installed earlier versions get the new desktop too. Only Vitrea's own defaults are
// changed: a wallpaper or theme someone picked themselves is left alone.

// Liquid Glass Plasma theme (replaces the old in-place "default" glass)
var theme = ConfigFile("plasmarc", "Theme");
var t = theme.readEntry("name");
if (t === "" || t === "default") {
    theme.writeEntry("name", "vitrea-liquid");
}

// animated login splash
var ks = ConfigFile("ksplashrc", "KSplash");
ks.writeEntry("Engine", "KSplashQML");
ks.writeEntry("Theme", "org.vitrea.glass.desktop");

// panels: replace the broken dashboard button with the Overview launcher
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "org.kde.plasma.kickerdash") {
            w.remove();
        }
        if (w.type === "org.kde.plasma.icontasks") {
            w.currentConfigGroup = ["General"];
            var l = String(w.readConfig("launchers", ""));
            if (l.indexOf("vitrea-overview.desktop") < 0) {
                w.writeConfig("launchers", "applications:vitrea-overview.desktop" + (l ? "," + l : ""));
            }
        }
    });
});

// desktop: Dusk wallpaper (if still on a Vitrea default) + clock and music widgets
desktops().forEach(function (d) {
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    var img = String(d.readConfig("Image", ""));
    if (img === "" || img.indexOf("/usr/share/wallpapers/Vitrea/") >= 0 || img === "Vitrea") {
        d.writeConfig("Image", "file:///usr/share/wallpapers/VitreaDusk/");
    }
    var have = {};
    d.widgets().forEach(function (w) { have[w.type] = true; });
    var g = screenGeometry(d.screen);
    if (!have["org.vitrea.clock"]) {
        var cw = Math.round(g.width * 0.22), ch = Math.round(g.height * 0.40);
        d.addWidget("org.vitrea.clock", g.width - cw - Math.round(g.width * 0.06), Math.round(g.height * 0.16), cw, ch);
    }
    if (!have["org.kde.plasma.mediacontroller"]) {
        var mw = Math.round(g.width * 0.24), mh = Math.round(g.height * 0.17);
        d.addWidget("org.kde.plasma.mediacontroller", Math.round(g.width * 0.03), g.height - mh - Math.round(g.height * 0.14), mw, mh);
    }
});
