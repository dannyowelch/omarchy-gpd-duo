import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.dannyowelch.gpd-duo"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property string pluginDir: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string ctl: pluginDir + "/gpd-duo-ctl"

  property var status: Model.emptyStatus()
  property bool busy: false
  property string lastError: ""
  property int selectedIndex: 0
  property bool cursorActive: false

  // Re-read on refresh so a Model.js change is not stuck behind a cached import.
  property int layoutRevision: 0
  readonly property var modes: {
    layoutRevision
    return Model.modes()
  }
  readonly property string currentMode: status.mode || "unknown"
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    refresh()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    root.layoutRevision++
    if (!statusProc.running) statusProc.running = true
  }

  function applyMode(mode) {
    if (!mode || root.busy) return
    root.lastError = ""
    root.busy = true
    actionProc.command = [root.ctl, "apply", String(mode)]
    actionProc.running = true
  }

  function saveLayout() {
    if (root.busy) return
    root.lastError = ""
    root.busy = true
    actionProc.command = [root.ctl, "save"]
    actionProc.running = true
  }

  function ingest(raw) {
    root.status = Model.parseStatus(raw)
    var idx = Model.modeIndex(root.status.lastMode || root.status.mode)
    if (!root.cursorActive) root.selectedIndex = idx
  }

  function moveCursor(delta) {
    var next = selectedIndex + delta
    if (next < 0) next = 0
    if (next > modes.length - 1) next = modes.length - 1
    selectedIndex = next
    cursorActive = true
  }

  function activateCursor() {
    if (selectedIndex >= 0 && selectedIndex < modes.length)
      applyMode(modes[selectedIndex].id)
  }

  Component.onCompleted: refresh()

  onOpenedChanged: {
    if (opened) {
      refresh()
      cursorActive = false
      selectedIndex = Model.modeIndex(status.lastMode || status.mode)
    }
  }

  Process {
    id: statusProc
    command: [root.ctl, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.ingest(text)
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (String(text || "").trim() !== "") root.ingest(text)
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var err = String(text || "").trim()
        if (err) root.lastError = err.replace(/^gpd-duo-ctl: /, "")
      }
    }
    onRunningChanged: if (!running) {
      root.busy = false
      root.refresh()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.moveCursor(dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: "󰍺"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "GPD Duo"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: {
                if (!root.status.isDuo) return "NOT A GPD DUO"
                if (root.busy) return "APPLYING"
                var live = Model.modeLabel(root.status.mode).toUpperCase()
                if (root.status.saved) return live + " · SAVED"
                if (root.status.lastMode && root.status.lastMode !== root.status.mode)
                  return live
                return live
              }
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator {
          foreground: root.contentForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: !root.status.isDuo

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "This plugin only applies layouts on a GPD Duo. DMI reports "
                  + (root.status.vendor || "unknown") + " "
                  + (root.status.product || "unknown") + "."
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(10)
          visible: root.status.isDuo

          PanelSectionHeader {
            text: "LAYOUT"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Repeater {
            model: root.modes

            ModeRow {
              required property var modelData
              required property int index
              width: panelColumn.width
              mode: modelData
              rowIndex: index
            }
          }
        }

        PanelSeparator {
          visible: root.status.isDuo
          foreground: root.contentForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.status.isDuo

          PanelSectionHeader {
            text: "DISPLAYS"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Text {
            width: parent.width
            text: Model.monitorLine(root.status.lower, "Lower")
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: Model.monitorLine(root.status.upper, "Upper")
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            visible: root.lastError !== ""
            text: root.lastError
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        Button {
          width: parent.width
          visible: root.status.isDuo
          text: root.status.saved ? "Saved to monitors.lua" : "Save to monitors.lua"
          bordered: true
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          enabled: !root.busy
          onClicked: root.saveLayout()
        }

        Text {
          width: parent.width
          visible: root.status.isDuo
          wrapMode: Text.WordWrap
          text: "Display layouts only. Touch and stylus mapping are not handled yet."
          color: Qt.darker(root.contentForeground, 1.4)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  component ModeRow: CursorSurface {
    id: modeRow
    required property var mode
    required property int rowIndex

    hasCursor: root.cursorActive && root.selectedIndex === rowIndex
    current: root.currentMode === mode.id
    foreground: root.contentForeground
    fill: Style.hoverFillFor(root.contentForeground, Color.accent)
    currentFill: Style.selectedFillFor(root.contentForeground, Color.accent)
    implicitHeight: modeInner.implicitHeight + Style.spacing.xl
    opacity: root.busy ? 0.55 : 1.0

    Row {
      id: modeInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        text: modeRow.mode.icon
        color: root.contentForeground
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.title
        width: Style.space(22)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        width: parent.width - Style.space(22) - Style.space(14) - Style.space(16)
        spacing: Style.space(2)
        anchors.verticalCenter: parent.verticalCenter

        Text {
          width: parent.width
          text: modeRow.mode.label
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: modeRow.mode.detail
          color: Qt.darker(root.contentForeground, 1.4)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }

      Text {
        text: modeRow.current ? "󰄬" : ""
        color: root.contentForeground
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.subtitle
        width: Style.space(14)
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
      onContainsMouseChanged: if (containsMouse) {
        root.cursorActive = true
        root.selectedIndex = modeRow.rowIndex
      }
      onClicked: if (!root.busy) root.applyMode(modeRow.mode.id)
    }
  }
}
