import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

PanelWindow {
  id: root

  property string fontFamily: Style.font.family
  property color foreground: Color.foreground
  property var anchorItem: null

  property bool confirming: false
  property bool running: false
  property bool succeeded: false
  property real progress: 0
  property string stepLabel: ""
  property string error: ""
  property bool open: false

  signal confirmRequested()
  signal dismissRequested()

  readonly property var anchorWindow: anchorItem && anchorItem.QsWindow ? anchorItem.QsWindow.window : null
  readonly property color dimForeground: Qt.darker(root.foreground, 1.4)
  readonly property bool canDismiss: !root.running
  readonly property string headingText: {
    if (root.confirming) return "Fix login screen orientation"
    if (root.running) return "Applying login screen fix"
    if (root.succeeded) return "Orientation fix installed"
    return "Orientation fix failed"
  }
  readonly property string statusText: {
    if (root.error !== "") return root.error
    if (root.succeeded) return root.stepLabel || "Login screen orientation is fixed."
    return root.stepLabel || "Working…"
  }
  readonly property var explanation: Model.loginFixExplanation()

  screen: root.anchorWindow ? root.anchorWindow.screen : null
  visible: open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "gpd-duo-login-fix"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; bottom: true; left: true; right: true }

  onOpenChanged: if (open) Qt.callLater(function() { if (root.open) keyCatcher.forceActiveFocus() })

  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.72)

    MouseArea {
      anchors.fill: parent
      onClicked: if (root.canDismiss) root.dismissRequested()
    }
  }

  Item {
    id: keyCatcher
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: if (root.canDismiss) root.dismissRequested()
    Keys.onReturnPressed: if (root.confirming) root.confirmRequested()
    Keys.onEnterPressed: if (root.confirming) root.confirmRequested()

    BorderSurface {
      id: card
      width: Math.min(parent.width - Style.space(32), Style.space(440))
      height: Math.min(
        parent.height - Style.space(32),
        cardInner.implicitHeight + Style.space(36) + card.contentTopInset + card.contentBottomInset
      )
      anchors.centerIn: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      padding: Style.space(18)
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent; onClicked: {} }

      Flickable {
        id: bodyFlick
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        contentWidth: width
        contentHeight: cardInner.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
          id: cardInner
          width: bodyFlick.width
          spacing: Style.space(12)

          Text {
            width: parent.width
            text: "LOGIN SCREEN"
            color: root.dimForeground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.4
          }

          Text {
            width: parent.width
            text: root.headingText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            wrapMode: Text.WordWrap
          }

          Column {
            width: parent.width
            spacing: Style.space(10)
            visible: root.confirming

            Repeater {
              model: root.explanation

              Text {
                required property var modelData
                width: cardInner.width
                text: String(modelData)
                color: root.dimForeground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }
            }
          }

          Text {
            width: parent.width
            visible: !root.confirming
            text: root.statusText
            color: root.dimForeground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
          }

          Item {
            width: parent.width
            height: Style.space(10)
            visible: !root.confirming

            Rectangle {
              id: track
              anchors.left: parent.left
              anchors.right: pctLabel.left
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              height: Math.max(4, Style.space(6))
              radius: height / 2
              color: Style.selectedFillFor(root.foreground, Color.accent)

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, root.progress / 100))
                radius: parent.radius
                color: Color.accent

                Behavior on width {
                  NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
              }
            }

            Text {
              id: pctLabel
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(root.progress) + "%"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              width: Style.space(36)
              horizontalAlignment: Text.AlignRight
            }
          }

          Text {
            width: parent.width
            visible: root.running
            wrapMode: Text.WordWrap
            text: "Leave this window open until it finishes."
            color: root.dimForeground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            width: parent.width
            spacing: Style.space(10)
            visible: root.confirming

            Button {
              width: (parent.width - parent.spacing) / 2
              text: "Cancel"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.dismissRequested()
            }

            Button {
              width: (parent.width - parent.spacing) / 2
              text: "Ok"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.confirmRequested()
            }
          }

          Button {
            width: parent.width
            visible: !root.confirming && !root.running
            text: "Dismiss"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.dismissRequested()
          }
        }
      }
    }
  }
}
