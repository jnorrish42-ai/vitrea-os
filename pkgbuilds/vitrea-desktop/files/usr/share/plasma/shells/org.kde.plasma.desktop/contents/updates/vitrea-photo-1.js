// Vitrea: the generated Night / Dusk / Neon wallpapers were replaced by real photographs.
// Anyone still on one of them moves to "summer 1am" (a lake at dusk, by Risto Saukonpää).
desktops().forEach(function (d) {
    if (d.wallpaperPlugin !== "org.kde.image") {
        return;
    }
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    var img = String(d.readConfig("Image", ""));
    if (img === "" || /\/wallpapers\/Vitrea(Dusk|Neon|Liquid)?\/?/.test(img) || /^Vitrea(Dusk|Neon)?$/.test(img)) {
        d.writeConfig("Image", "file:///usr/share/wallpapers/summer_1am/");
        d.reloadConfig();
    }
});
