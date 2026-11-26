#!/usr/bin/env python3
"""Vitrea Style: wallpaper, colours, transparency, motion, desktop, keyboard and Mac settings.
Every change applies straight away."""
import glob
import os
import re
import subprocess
import sys

from PyQt6.QtCore import QObject, QUrl, pyqtSlot, pyqtProperty
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
WALLPAPERS = {  # photos from KDE's plasma-workspace-wallpapers
    'lake': '/usr/share/wallpapers/summer_1am',
    'mist': '/usr/share/wallpapers/DarkestHour',
    'forest': '/usr/share/wallpapers/Path',
    'ember': '/usr/share/wallpapers/FallenLeaf',
}
THEMES = {'more': 'vitrea-liquid-clear', 'normal': 'vitrea-liquid', 'less': 'vitrea-liquid-frosted'}
SPEEDS = {'fast': '0.55', 'normal': '1.0', 'slow': '1.5'}
MAC_HELPER = '/usr/lib/vitrea/mac-settings'
FAN_PROFILES = {('60', '85', 'exponential'): 'quiet', ('55', '75', 'linear'): 'balanced',
                ('45', '68', 'logarithmic'): 'cool'}


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
    return run('qdbus6', 'org.kde.plasmashell', '/PlasmaShell', 'org.kde.PlasmaShell.evaluateScript', js)


def read(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return ''


class Backend(QObject):
    # ---------- current state (read once at start) ----------
    @pyqtProperty(str, constant=True)
    def wallpaper(self):
        out = shell('var d = desktops()[0]; d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]; '
                    'print(d.readConfig("Image", ""));')
        for k, path in WALLPAPERS.items():
            if os.path.basename(path) in out:
                return k
        return ''

    @pyqtProperty(bool, constant=True)
    def dark(self):
        return 'Light' not in rd('kdeglobals', 'General', 'ColorScheme', 'VitreaDark')

    @pyqtProperty(bool, constant=True)
    def accentAuto(self):
        return rd('kdeglobals', 'General', 'accentColorFromWallpaper', 'false') == 'true'

    @pyqtProperty(str, constant=True)
    def transparency(self):
        t = rd('plasmarc', 'Theme', 'name', 'vitrea-liquid')
        return next((k for k, v in THEMES.items() if v == t), 'normal')

    @pyqtProperty(str, constant=True)
    def glassMode(self):
        return rd('vitrearc', 'Glass', 'Mode', 'auto')

    @pyqtProperty(str, constant=True)
    def speed(self):
        try:
            f = float(rd('kdeglobals', 'KDE', 'AnimationDurationFactor', '1.0'))
        except ValueError:
            f = 1.0
        return min(SPEEDS, key=lambda k: abs(float(SPEEDS[k]) - f))

    @pyqtProperty(bool, constant=True)
    def magicLamp(self):
        return rd('kwinrc', 'Plugins', 'magiclampEnabled', 'false') == 'true'

    @pyqtProperty(bool, constant=True)
    def wobbly(self):
        return rd('kwinrc', 'Plugins', 'wobblywindowsEnabled', 'false') == 'true'

    @pyqtProperty(str, constant=True)
    def widgets(self):
        """Comma-separated list of the widget types on the desktop."""
        return shell('var s = {}; desktops().forEach(function (d) { d.widgets().forEach(function (w) '
                     '{ s[w.type] = 1; }); }); print(Object.keys(s).join(","));')

    @pyqtProperty(bool, constant=True)
    def lite(self):
        return rd('vitrearc', 'Performance', 'Lite', 'false') == 'true'

    @pyqtSlot(bool)
    def setLite(self, on):
        run('/usr/lib/vitrea/lite', 'on' if on else 'off')

    @pyqtProperty(bool, constant=True)
    def macKeys(self):
        return rd('vitrearc', 'Keyboard', 'MacStyle', 'false') == 'true'

    @pyqtProperty(bool, constant=True)
    def appleHardware(self):
        return read('/sys/class/dmi/id/sys_vendor') == 'Apple Inc.'

    @pyqtProperty(bool, constant=True)
    def macHelper(self):
        return os.access(MAC_HELPER, os.X_OK)

    @pyqtProperty(bool, constant=True)
    def hasTouchBar(self):
        return os.path.exists('/usr/share/tiny-dfr/config.toml') and os.path.exists('/sys/class/backlight/appletb_backlight')

    @pyqtProperty(str, constant=True)
    def touchBar(self):
        for f in ('/etc/tiny-dfr/config.toml', '/usr/share/tiny-dfr/config.toml'):
            m = re.search(r'^MediaLayerDefault\s*=\s*(\w+)', read(f), re.M)
            if m:
                return 'media' if m.group(1) == 'true' else 'fkeys'
        return 'fkeys'

    @pyqtProperty(str, constant=True)
    def fanProfile(self):
        conf = read('/etc/t2fand.conf')
        if re.search(r'^always_full_speed\s*=\s*true', conf, re.M):
            return 'max'

        def get(k):
            m = re.search(rf'^{k}\s*=\s*(\S+)', conf, re.M)
            return m.group(1) if m else ''
        return FAN_PROFILES.get((get('low_temp'), get('high_temp'), get('speed_curve')), 'balanced')

    @pyqtSlot(result=str)
    def sensors(self):
        """For example 'CPU 52 °C  ·  Fans 1800 / 1750 rpm' (whatever the machine reports)."""
        parts, temps, rpms = [], [], []
        for hw in glob.glob('/sys/class/hwmon/hwmon*'):
            if read(f'{hw}/name') in ('coretemp', 'k10temp', 'zenpower'):
                for t in glob.glob(f'{hw}/temp*_input'):
                    try:
                        temps.append(int(read(t)) / 1000)
                    except ValueError:
                        pass
        fans = glob.glob('/sys/devices/pci*/*/*/*/APP0001:00/fan*_input') or glob.glob('/sys/class/hwmon/hwmon*/fan*_input')
        for f in sorted(fans):
            try:
                rpms.append(int(read(f)))
            except ValueError:
                pass
        if temps:
            parts.append(f'CPU {round(max(temps))} °C')
        if rpms:
            parts.append(('Fan ' if len(rpms) == 1 else 'Fans ') + ' / '.join(str(r) for r in rpms) + ' rpm')
        return '  ·  '.join(parts)

    # ---------- actions ----------
    @pyqtSlot(str)
    def setWallpaper(self, name):
        wall = WALLPAPERS[name]
        run('plasma-apply-wallpaperimage', wall)
        # the lock screen shows the same photo
        run('kwriteconfig6', '--file', 'kscreenlockerrc', '--group', 'Greeter', '--group', 'Wallpaper',
            '--group', 'org.kde.image', '--group', 'General', '--key', 'Image', 'file://' + wall + '/')

    @pyqtSlot(bool)
    def setDark(self, dark):
        run('/usr/bin/vitrea-appearance', 'dark' if dark else 'light')

    @pyqtSlot()
    def setAccentAuto(self):
        wr('kdeglobals', 'General', 'accentColorFromWallpaper', 'true')

    @pyqtSlot(str)
    def setAccent(self, colour):
        wr('kdeglobals', 'General', 'accentColorFromWallpaper', 'false')
        run('plasma-apply-colorscheme', '--accent-color', colour)

    @pyqtSlot(str)
    def setTransparency(self, level):
        run('plasma-apply-desktoptheme', THEMES[level])

    @pyqtSlot(str)
    def setGlassMode(self, mode):
        wr('vitrearc', 'Glass', 'Mode', mode)
        run('/usr/lib/vitrea/glass-guard')    # applies it the same way the login-time check does
        if mode == 'on':
            wr('kwinrc', 'Plugins', 'glassEnabled', 'true')
            wr('kwinrc', 'Plugins', 'blurEnabled', 'false')
            wr('kwinrc', 'Plugins', 'contrastEnabled', 'false')
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
    def setWobbly(self, on):
        wr('kwinrc', 'Plugins', 'wobblywindowsEnabled', 'true' if on else 'false')
        kwin_reconfigure()

    @pyqtSlot(str)
    def setDock(self, edge):
        shell('panels().forEach(function (p) { if (p.widgets("org.kde.plasma.icontasks").length && p.location != "top") '
              '{ p.location = "%s"; } });' % edge)

    @pyqtSlot(str, bool)
    def setWidget(self, plugin, on):
        if not on:
            shell('desktops().forEach(function (d) { d.widgets("%s").forEach(function (w) { w.remove(); }); });' % plugin)
            return
        geometry = {   # x, y, width, height
            'org.vitrea.clock': 'g.width * 0.72, g.height * 0.16, g.width * 0.22, g.height * 0.40',
            'org.vitrea.music': 'g.width * 0.03, g.height * 0.70, Math.max(400, g.width * 0.25), Math.max(150, g.height * 0.17)',
            'org.vitrea.yumeka': 'g.width * 0.77, g.height * 0.57, Math.max(300, g.width * 0.22), Math.max(420, g.height * 0.40)',
        }[plugin]
        shell('desktops().forEach(function (d) { if (!d.widgets("%s").length) { var g = screenGeometry(d.screen); '
              'd.addWidget("%s", %s); } });' % (plugin, plugin, geometry))

    @pyqtSlot(bool)
    def setMacKeys(self, on):
        run('/usr/lib/vitrea/mac-keys', 'on' if on else 'off')

    @pyqtSlot(str)
    def setTouchBar(self, mode):
        run('pkexec', MAC_HELPER, 'touchbar', mode)

    @pyqtSlot(str)
    def setFans(self, profile):
        run('pkexec', MAC_HELPER, 'fans', profile)

    @pyqtSlot(str)
    def openSettings(self, page):
        cmd = ['systemsettings'] + ([page] if page else [])
        subprocess.Popen(cmd, start_new_session=True)


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName('vitrea-style')
    app.setApplicationDisplayName('Vitrea Style')
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
