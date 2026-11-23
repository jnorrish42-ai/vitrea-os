// The "time's up" sound.
import QtQuick
import QtMultimedia

Item {
    function play() { player.stop(); player.play() }
    MediaPlayer {
        id: player
        source: "file:///usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        audioOutput: AudioOutput { volume: 0.9 }
    }
}
