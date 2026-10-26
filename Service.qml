import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import "Model.js" as Model

// Shows the card after each capture and owns the Print Screen binding.
//
// bin/screenshot-clip calls `omarchy-shell slylem0.screenshot-clip show <file>`
// once the image is on the clipboard; the card then offers Save, Edit and
// Close. While the plugin is enabled this service binds Print Screen to the
// script through `hyprctl eval`, so nothing in ~/.config/hypr needs editing,
// and puts Omarchy's own binding back when the plugin is disabled. A Hyprland
// config reload resets bindings, so it binds again after each one.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null

  readonly property string pluginPath: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, ""))
  readonly property string helper: pluginPath + "/bin/screenshot-clip"

  property var settings: Model.cleanSettings({})
  readonly property string lang: Model.language(settings.language, Qt.locale().name)

  property string current: ""
  property string status: ""
  property string screenName: ""
  property real remaining: 1.0
  property bool hovered: false
  property bool bound: false

  function show(path) {
    root.current = path
    root.status = ""
    root.remaining = 1.0
    var monitor = Hyprland.focusedMonitor
    root.screenName = monitor ? monitor.name : ""
  }

  function dismiss() {
    root.current = ""
    root.status = ""
  }

  function save() {
    if (!root.current || saveProcess.running) return
    root.status = "saving"
    saveProcess.command = [root.helper, "save", root.current]
    saveProcess.running = true
  }

  function edit() {
    if (!root.current) return
    Quickshell.execDetached(["env", "SCREENSHOT_CLIP_LANG=" + root.lang, root.helper, "edit", root.current])
    root.dismiss()
  }

  function applyBinding() {
    if (root.settings.takeOverPrint) {
      Quickshell.execDetached(["hyprctl", "eval", Model.bindLua(root.helper, root.lang, root.settings.keep)])
      root.bound = true
    } else if (root.bound) {
      Quickshell.execDetached(["hyprctl", "eval", Model.restoreLua()])
      root.bound = false
    }
  }

  onSettingsChanged: rebind.restart()
  onLangChanged: rebind.restart()
  Component.onCompleted: rebind.restart()
  Component.onDestruction: {
    if (root.bound) Quickshell.execDetached(["hyprctl", "eval", Model.restoreLua()])
  }

  Timer {
    id: rebind
    interval: 300
    onTriggered: root.applyBinding()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && String(event.name) === "configreloaded") rebind.restart()
    }
  }

  // Settings are the bar widget's, stored inline in its shell.json entry. Read
  // them here so they apply even when the widget is not on the bar.
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.settings = Model.cleanSettings(Model.settingsFromShellConfig(text(), Model.PLUGIN_ID))
    onLoadFailed: root.settings = Model.cleanSettings({})
  }

  IpcHandler {
    target: Model.PLUGIN_ID
    function show(path: string): string { root.show(path); return "ok" }
    function dismiss(): string { root.dismiss(); return "ok" }
    // Act on the card from the keyboard, e.g. bind a key to `save`.
    function save(): string { if (!root.current) return "none"; root.save(); return "ok" }
    function edit(): string { if (!root.current) return "none"; root.edit(); return "ok" }
    function ping(): string { return "ok" }
  }

  Process {
    id: saveProcess
    onExited: function(exitCode) {
      root.status = exitCode === 0 ? "saved" : "failed"
      if (exitCode === 0) closeAfterSave.restart()
    }
  }

  Timer {
    id: closeAfterSave
    interval: 1600
    onTriggered: root.dismiss()
  }

  // Drains the countdown; hovering the card or a save in progress pauses it.
  Timer {
    interval: 50
    repeat: true
    running: root.current !== "" && !root.hovered && root.status === ""
    onTriggered: {
      root.remaining -= 50 / (root.settings.seconds * 1000)
      if (root.remaining <= 0) root.dismiss()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      visible: root.current !== "" && (root.screenName === "" || root.screenName === modelData.name)
      color: "transparent"
      anchors {
        bottom: true
        right: true
      }
      margins {
        bottom: Style.space(16)
        right: Style.space(16)
      }
      implicitWidth: card.implicitWidth
      implicitHeight: card.implicitHeight
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "screenshot-clip"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Card {
        id: card
        anchors.fill: parent
        path: root.current
        lang: root.lang
        status: root.status
        remaining: root.remaining
        onHoveredChanged: root.hovered = hovered
        onSaveRequested: root.save()
        onEditRequested: root.edit()
        onCloseRequested: root.dismiss()
      }
    }
  }
}
