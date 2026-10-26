import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Bar button for the recent-screenshots panel. Left click opens the panel;
// right click takes a screenshot right away.
BarWidget {
  id: root
  moduleName: Model.PLUGIN_ID

  property bool alive: true
  property var items: []
  readonly property string lang: Model.language(setting("language", "auto"), Qt.locale().name)
  readonly property string pluginPath: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, ""))
  readonly property string helper: pluginPath + "/bin/screenshot-clip"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function refresh() {
    if (!listProcess.running) listProcess.running = true
  }

  function run(action, path) {
    actionProcess.command = ["env", "SCREENSHOT_CLIP_LANG=" + root.lang, root.helper, action, path]
    actionProcess.running = true
  }

  function capture() {
    Quickshell.execDetached(["env", "SCREENSHOT_CLIP_LANG=" + root.lang,
      "SCREENSHOT_CLIP_KEEP=" + Model.cleanSettings(root.settings).keep, root.helper])
  }

  function edit(path) {
    Quickshell.execDetached(["env", "SCREENSHOT_CLIP_LANG=" + root.lang, root.helper, "edit", path])
    root.close()
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.anchorItem = button
    target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onOpenedChanged: if (opened) refresh()
  Component.onCompleted: refresh()

  // Captures arrive from outside the shell, so poll while the panel is open.
  Timer {
    interval: 2000
    repeat: true
    running: root.opened
    onTriggered: root.refresh()
  }

  Process {
    id: listProcess
    command: [root.helper, "list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (root.alive) root.items = Model.parseList(text)
    }
  }

  // Panel.qml reads the outcome of save from here to mark the row.
  property var savedPaths: ({})
  property string pendingAction: ""
  property string pendingPath: ""

  Process {
    id: actionProcess
    onStarted: {
      root.pendingAction = actionProcess.command[3]
      root.pendingPath = actionProcess.command[4]
    }
    onExited: function(exitCode) {
      if (!root.alive) return
      if (root.pendingAction === "save" && exitCode === 0) {
        var next = Object.assign({}, root.savedPaths)
        next[root.pendingPath] = true
        root.savedPaths = next
      }
      root.pendingAction = ""
      root.refresh()
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\u{F0E51}"
    tooltipText: Model.tr(root.lang, "tooltip")
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.capture()
      else root.toggle()
    }
  }

  Component.onDestruction: {
    alive = false
    listProcess.running = false
  }
}
