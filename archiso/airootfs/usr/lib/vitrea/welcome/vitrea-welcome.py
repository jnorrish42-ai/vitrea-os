#!/usr/bin/env python3
"""Vitrea Welcome: a friendly first-run hub (install, apps, Wi-Fi, appearance)."""
import os
import shutil
import subprocess
import sys

from PyQt6.QtCore import QObject, QUrl, pyqtSlot, pyqtProperty
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
CONF_DIR = os.path.join(os.path.expanduser("~"), ".config", "vitrea")
SKIP_FILE = os.path.join(CONF_DIR, "welcome-done")


def is_live():
    try:
        with open("/proc/cmdline") as f:
            return "archisobasedir" in f.read()
    except OSError:
        return False


class Backend(QObject):
    @pyqtProperty(bool, constant=True)
    def live(self):
        return is_live()

    @pyqtProperty(bool, constant=True)
    def darkMode(self):
        try:
            out = subprocess.run(["kreadconfig6", "--group", "General", "--key", "ColorScheme"],
                                 capture_output=True, text=True).stdout
            return "Dark" in out or "Night" in out
        except OSError:
            return False

    @pyqtProperty(bool, constant=True)
    def showAtStartup(self):
        return not os.path.exists(SKIP_FILE)

    @pyqtSlot(bool)
    def setShowAtStartup(self, show):
        os.makedirs(CONF_DIR, exist_ok=True)
        if show and os.path.exists(SKIP_FILE):
            os.remove(SKIP_FILE)
        elif not show:
            open(SKIP_FILE, "w").close()

    @pyqtSlot(str)
    def run(self, action):
        cmds = {
            "install": ["vitrea-install"],
            "apps": ["plasma-discover"],
            "hyprland": ["dbus-send", "--session", "--dest=org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt.promptLogout"],
            "wifi": ["systemsettings", "kcm_networkmanagement"],
            "settings": ["systemsettings"],
            "display": ["systemsettings", "kcm_kscreen"],
            "updates": ["plasma-discover", "--mode", "update"],
            "light": ["vitrea-appearance", "light"],
            "dark": ["vitrea-appearance", "dark"],
            "help": ["xdg-open", "https://wiki.archlinux.org/"],
        }
        cmd = cmds.get(action)
        if cmd and shutil.which(cmd[0]):
            subprocess.Popen(cmd, start_new_session=True)


def main():
    if "--autostart" in sys.argv and os.path.exists(SKIP_FILE) and not is_live():
        return 0
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Vitrea Welcome")
    app.setDesktopFileName("vitrea-welcome")
    app.setWindowIcon(QIcon.fromTheme("vitrea-logo"))
    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "Welcome.qml")))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
