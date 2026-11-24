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

// desktop: default photo wallpaper (if still on a Vitrea default) + the Now Playing card
desktops().forEach(function (d) {
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    var img = String(d.readConfig("Image", ""));
    if (img === "" || img.indexOf("/usr/share/wallpapers/Vitrea/") >= 0 || img === "Vitrea") {
        d.writeConfig("Image", "file:///usr/share/wallpapers/summer_1am/");
    }
    var have = {};
    d.widgets().forEach(function (w) { have[w.type] = true; });
    var g = screenGeometry(d.screen);
    if (!have["org.vitrea.music"]) {
        var mw = Math.max(400, Math.round(g.width * 0.25)), mh = Math.max(150, Math.round(g.height * 0.17));
        d.addWidget("org.vitrea.music", Math.round(g.width * 0.03), g.height - mh - Math.round(g.height * 0.13), mw, mh);
    }
});
