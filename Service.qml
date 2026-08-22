import QtQuick
import Quickshell.Io

Item {
  id: root

  property var shell: null
  readonly property string pluginDir: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string ctl: pluginDir + "/gpd-duo-ctl"
  readonly property string sliderd: pluginDir + "/gpd-duo-sliderd"

  Component.onCompleted: {
    boot.running = true
    sliderdProc.running = true
  }

  Process {
    id: boot
    command: [root.ctl, "boot"]
  }

  Process {
    id: sliderdProc
    command: [root.sliderd]
    onExited: sliderdRestart.restart()
  }

  Timer {
    id: sliderdRestart
    interval: 1500
    onTriggered: sliderdProc.running = true
  }
}
