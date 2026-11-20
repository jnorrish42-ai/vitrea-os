#!/usr/bin/env python3
"""Render the Vitrea SDDM theme offscreen with mocked SDDM objects (for quick visual checks).
Usage: preview-sddm.py THEME_DIR OUT.png [WIDTH HEIGHT]"""
import os, sys
os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
from PyQt6.QtCore import QObject, QUrl, Qt, QTimer, pyqtSignal, pyqtSlot, pyqtProperty, QByteArray
from PyQt6.QtGui import QGuiApplication, QStandardItemModel, QStandardItem
from PyQt6.QtQml import QQmlPropertyMap
from PyQt6.QtQuick import QQuickView

theme, out = sys.argv[1], sys.argv[2]
w, h = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (1920, 1080)


class Sddm(QObject):
    loginFailed = pyqtSignal()
    loginSucceeded = pyqtSignal()
    informationMessage = pyqtSignal(str)

    @pyqtProperty(bool, constant=True)
    def canPowerOff(self): return True
    @pyqtProperty(bool, constant=True)
    def canReboot(self): return True
    @pyqtProperty(bool, constant=True)
    def canSuspend(self): return True

    @pyqtSlot(str, str, int)
    def login(self, u, p, s): print('login', u, s); self.loginFailed.emit()
    @pyqtSlot()
    def powerOff(self): pass
    @pyqtSlot()
    def reboot(self): pass
    @pyqtSlot()
    def suspend(self): pass


class Model(QStandardItemModel):
    def __init__(self, roles, rows, last):
        super().__init__()
        self._roles = {Qt.ItemDataRole.UserRole + i + 1: QByteArray(r.encode()) for i, r in enumerate(roles)}
        for row in rows:
            it = QStandardItem()
            for i, v in enumerate(row):
                it.setData(v, Qt.ItemDataRole.UserRole + i + 1)
            self.appendRow(it)
        self._last = last

    def roleNames(self): return self._roles
    @pyqtProperty(int, constant=True)
    def lastIndex(self): return self._last
    @pyqtProperty(str, constant=True)
    def lastUser(self): return 'live'


app = QGuiApplication(sys.argv)
view = QQuickView()
sddm = Sddm()
users = Model(['name', 'realName', 'icon', 'homeDir'], [['live', 'Vitrea Live', '', '/home/live']], 0)
sessions = Model(['name', 'file', 'comment'], [['Plasma (Wayland)', 'plasma.desktop', ''], ['Hyprland (43PR)', '43pr-hyprland.desktop', '']], 0)
config = QQmlPropertyMap()
bg = os.environ.get('BG', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'pkgbuilds', 'vitrea-desktop', 'files', 'usr/share/wallpapers/Vitrea/contents/images/3840x2160.png'))
config.insert('background', 'file://' + bg)
ctx = view.rootContext()
for k, v in (('sddm', sddm), ('userModel', users), ('sessionModel', sessions), ('config', config)):
    ctx.setContextProperty(k, v)
view.setResizeMode(QQuickView.ResizeMode.SizeRootObjectToView)
view.resize(w, h)
view.setSource(QUrl.fromLocalFile(os.path.join(theme, 'Main.qml')))
for e in view.errors():
    print('QML ERROR:', e.toString())
view.show()


def grab():
    view.grabWindow().save(out)
    print('saved', out)
    app.quit()


QTimer.singleShot(1500, grab)
app.exec()
