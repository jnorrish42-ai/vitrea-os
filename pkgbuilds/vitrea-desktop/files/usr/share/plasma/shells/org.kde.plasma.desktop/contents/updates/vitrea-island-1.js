// Vitrea Island replaces the clock in the middle of Vitrea's top bar (runs once per user, at login).
// Only Vitrea's own default top bar is touched: kickoff + pager + clock + tray, at the top edge.
panels().forEach(function (p) {
    if (p.location !== "top") return;
    var types = p.widgets().map(function (w) { return w.type; });
    if (types.indexOf("org.vitrea.island") >= 0) return;
    if (types.indexOf("org.kde.plasma.digitalclock") < 0 || types.indexOf("org.kde.plasma.kickoff") < 0) return;
    // panels can't reorder widgets from scripts, so rebuild the bar in the same order
    p.widgets().forEach(function (w) { w.remove(); });
    var menu = p.addWidget("org.kde.plasma.kickoff");
    menu.currentConfigGroup = ["General"];
    menu.writeConfig("icon", "vitrea-logo");
    menu.writeConfig("favoritesDisplay", 0);
    var pager = p.addWidget("org.kde.plasma.pager");
    pager.currentConfigGroup = ["General"];
    pager.writeConfig("displayedText", 0);
    pager.writeConfig("showWindowOutlines", false);
    pager.writeConfig("showWindowIcons", false);
    pager.writeConfig("wrapPage", true);
    p.addWidget("org.kde.plasma.panelspacer");
    p.addWidget("org.vitrea.island");
    p.addWidget("org.kde.plasma.panelspacer");
    p.addWidget("org.kde.plasma.systemtray");
});
