import QtQuick

// Headless. The capture runs from bin/screenshot-clip, bound to Print Screen in
// ~/.config/hypr/bindings.lua; this service only gives the plugin something for
// the shell to load, so it can be listed, enabled and updated like any other.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null
}
