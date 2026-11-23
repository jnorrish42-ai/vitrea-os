// Vitrea: Yumeka Kuroha joins the desktop (runs once per user, at login).
desktops().forEach(function (d) {
    if (d.widgets("org.vitrea.yumeka").length) return;
    var g = screenGeometry(d.screen);
    var yw = Math.max(300, Math.round(g.width * 0.22)), yh = Math.max(420, Math.round(g.height * 0.40));
    d.addWidget("org.vitrea.yumeka", g.width - yw - Math.round(g.width * 0.015), g.height - yh - Math.round(g.height * 0.03), yw, yh);
});
