import QtQuick
import Quickshell.Io

Item {
  id: root

  property var shell: null
  readonly property string ctl: String(Qt.resolvedUrl("gpd-duo-ctl")).replace(/^file:\/\//, "")

  Component.onCompleted: boot.running = true

  Process {
    id: boot
    command: [root.ctl, "boot"]
  }
}
