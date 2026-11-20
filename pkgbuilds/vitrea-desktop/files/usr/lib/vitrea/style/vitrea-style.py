#!/usr/bin/env python3
"""Vitrea Style: one place to customise the Liquid look. Every change applies immediately."""
import os
import subprocess
import sys

from PyQt6.QtCore import QObject, QUrl, pyqtSlot, pyqtProperty
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
PRESETS = {  # wallpaper package, accent colour
    'night': ('/usr/share/wallpapers/Vitrea', '#cba6f7'),
    'dusk': ('/usr/share/wallpapers/VitreaDusk', '#f5a3b8'),
    'neon': ('/usr/share/wallpapers/VitreaNeon', '#22d3ee'),
}
GLASS_THEMES = {'clear': 'vitrea-liquid-clear', 'liquid': 'vitrea-liquid', 'frosted': 'vitrea-liquid-frosted'}
SPEEDS = {'snappy': '0.55', 'fluid': '1.0', 'relaxed': '1.5'}


def run(*cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=30).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ''


def rd(file, group, key, default=''):
    return run('kreadconfig6', '--file', file, '--group', group, '--key', key, '--default', default)


def wr(file, group, key, value):
    run('kwriteconfig6', '--file', file, '--group', group, '--key', key, str(value))


def kwin_reconfigure():
    run('qdbus6', 'org.kde.KWin', '/KWin', 'reconfigure')


def shell(js):
    run('qdbus6', 'org.kde.plasmashell', '/PlasmaShell', 'org.kde.PlasmaShell.evaluateScript', js)


class Backend(QObject):
    # ---- current state (read once at start) ----
    @pyqtProperty(str, constant=True)
    def glass(self):
        t = rd('plasmarc', 'Theme', 'name', 'vitrea-liquid')
        return next((k for k, v in GLASS_THEMES.items() if v == t), 'liquid')

    @pyqtProperty(str, constant=True)
    def glassMode(self):
        return rd('vitrearc', 'Glass', 'Mode', 'auto')

    @pyqtProperty(int, constant=True)
    def refraction(self):
        try:
            return int(rd('kwinrc', 'Effect-blurplus', 'RefractionStrength', '10'))
        except ValueError:
            return 10

    @pyqtProperty(str, constant=True)
    def speed(self):
        f = rd('kdeglobals', 'KDE', 'AnimationDurationFactor', '1.0')
        return min(SPEEDS, key=lambda k: abs(float(SPEEDS[k]) - float(f or 1)))

    @pyqtProperty(bool, constant=True)
    def magicLamp(self):
        return rd('kwinrc', 'Plugins', 'magiclampEnabled', 'false') == 'true'

    @pyqtProperty(bool, constant=True)
    def jelly(self):
        return rd('kwinrc', 'Plugins', 'wobblywindowsEnabled', 'false') == 'true'

    # ---- actions ----
    @pyqtSlot(str)
    def setPreset(self, name):
        wall, accent = PRESETS[name]
        run('plasma-apply-wallpaperimage', wall)
        self.setAccent(accent)

    @pyqtSlot(str)
    def setAccent(self, colour):
        run('plasma-apply-colorscheme', '--accent-color', colour)

    @pyqtSlot(str)
    def setGlass(self, level):
        run('plasma-apply-desktoptheme', GLASS_THEMES[level])

    @pyqtSlot(str)
    def setGlassMode(self, mode):
        wr('vitrearc', 'Glass', 'Mode', mode)
        # apply now, the same way the login-time guard does
        run('/usr/lib/vitrea/glass-guard')
        if mode == 'on':
            wr('kwinrc', 'Plugins', 'glassEnabled', 'true')
            wr('kwinrc', 'Plugins', 'blurEnabled', 'false')
            wr('kwinrc', 'Plugins', 'contrastEnabled', 'false')
        kwin_reconfigure()

    @pyqtSlot(int)
    def setRefraction(self, v):
        wr('kwinrc', 'Effect-blurplus', 'RefractionStrength', v)
        kwin_reconfigure()

    @pyqtSlot(str)
    def setSpeed(self, s):
        wr('kdeglobals', 'KDE', 'AnimationDurationFactor', SPEEDS[s])
        kwin_reconfigure()

    @pyqtSlot(bool)
    def setMagicLamp(self, on):
        wr('kwinrc', 'Plugins', 'magiclampEnabled', 'true' if on else 'false')
        wr('kwinrc', 'Plugins', 'squashEnabled', 'false' if on else 'true')
        kwin_reconfigure()

    @pyqtSlot(bool)
    def setJelly(self, on):
        wr('kwinrc', 'Plugins', 'wobblywindowsEnabled', 'true' if on else 'false')
        kwin_reconfigure()

    @pyqtSlot(str)
    def setDock(self, edge):
        shell('panels().forEach(function (p) { if (p.widgets("org.kde.plasma.icontasks").length && p.location != "top") '
              '{ p.location = "%s"; } });' % edge)

    @pyqtSlot(str, bool)
    def setWidget(self, plugin, on):
        if on:
            shell('desktops().forEach(function (d) { if (!d.widgets("%s").length) { var g = screenGeometry(d.screen); '
                  'if ("%s" == "org.vitrea.clock") d.addWidget("%s", g.width * 0.72, g.height * 0.16, g.width * 0.22, g.height * 0.40); '
                  'else d.addWidget("%s", g.width * 0.03, g.height * 0.70, Math.max(400, g.width * 0.25), Math.max(150, g.height * 0.17)); } });'
                  % (plugin, plugin, plugin, plugin))
        else:
            shell('desktops().forEach(function (d) { d.widgets("%s").forEach(function (w) { w.remove(); }); });' % plugin)

    @pyqtSlot()
    def openSettings(self):
        subprocess.Popen(['systemsettings'], start_new_session=True)


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName('vitrea-style')
    app.setDesktopFileName('vitrea-style')
    app.setWindowIcon(QIcon.fromTheme('vitrea-logo'))
    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty('backend', backend)
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, 'Style.qml')))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
