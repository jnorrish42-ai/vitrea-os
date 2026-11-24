// Vitrea: a calmer default desktop. The big desktop clock and Yumeka are now optional
// (turn them back on in Vitrea Style); the Island in the top bar already shows the time.
desktops().forEach(function (d) {
    d.widgets("org.vitrea.clock").forEach(function (w) { w.remove(); });
    d.widgets("org.vitrea.yumeka").forEach(function (w) { w.remove(); });
});
