pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Recent screenshots: the temporary copies still in memory, newest first, each
// with Save, Edit, Copy and Delete. Lets you keep a capture after its card is
// gone, which the stock screenshot never needed because it saved everything.
Panel {
  id: root
  moduleName: Model.PLUGIN_ID
  ipcTarget: Model.PLUGIN_ID + ".panel"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property var items: hostWidget ? hostWidget.items : []
  readonly property var savedPaths: hostWidget ? hostWidget.savedPaths : ({})
  readonly property string lang: hostWidget ? hostWidget.lang : "en"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.65)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int inset: Style.space(14)

  property int cursorIndex: 0
  property bool cursorActive: false

  function tr(key) { return Model.tr(root.lang, key) }

  function act(action, index) {
    var item = root.items[index]
    if (!item || !root.hostWidget) return
    if (action === "edit") root.hostWidget.edit(item.path)
    else root.hostWidget.run(action, item.path)
  }

  function moveCursor(dy) {
    if (root.items.length === 0) return
    root.cursorIndex = Math.max(0, Math.min(root.items.length - 1, root.cursorIndex + dy))
  }

  onItemsChanged: if (cursorIndex >= items.length) cursorIndex = Math.max(0, items.length - 1)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    padding: Style.space(20)
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dy)
      }
      onActivateRequested: if (root.cursorActive) root.act("save", root.cursorIndex)
      onDeleteRequested: if (root.cursorActive) root.act("delete", root.cursorIndex)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (!root.cursorActive) return
        if (t === "e") root.act("edit", root.cursorIndex)
        else if (t === "c") root.act("copy", root.cursorIndex)
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: content
          width: parent.width
          spacing: 0

          Item { width: 1; height: Style.space(4) }

          PanelHero {
            width: parent.width
            title: root.tr("recent")
            meta: root.tr("recentMeta")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Item { width: 1; height: Style.space(16) }
          PanelSeparator { width: parent.width; foreground: root.foreground }
          Item { width: 1; height: Style.space(10) }

          Text {
            visible: root.items.length === 0
            width: parent.width
            leftPadding: root.inset
            rightPadding: root.inset
            topPadding: Style.space(8)
            bottomPadding: Style.space(8)
            text: root.tr("empty")
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Column {
            id: list
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: root.items

              BorderSurface {
                id: row
                required property var modelData
                required property int index
                readonly property bool hasCursor: root.cursorActive && root.cursorIndex === index
                readonly property bool saved: root.savedPaths[modelData.path] === true
                width: list.width
                height: Style.space(76)
                radius: Style.cornerRadius
                color: hasCursor ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
                borderSpec: hasCursor ? Border.controlSpec("hover-cursor", root.foreground, root.accent) : Border.none()

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: { root.cursorActive = true; root.cursorIndex = row.index }
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  spacing: Style.spacing.controlGap

                  Image {
                    Layout.preferredWidth: Style.space(104)
                    Layout.preferredHeight: Style.space(60)
                    source: Model.fileUrl(row.modelData.path)
                    sourceSize.width: Style.space(208)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.act("edit", row.index)
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(2)

                    Text {
                      Layout.fillWidth: true
                      text: row.modelData.time || "—"
                      textFormat: Text.PlainText
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.title
                      font.bold: row.index === 0
                      elide: Text.ElideRight
                    }

                    Text {
                      Layout.fillWidth: true
                      visible: row.saved
                      text: "\u{F012C} " + root.tr("saved")
                      textFormat: Text.PlainText
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                    }
                  }

                  PanelActionButton {
                    iconText: row.saved ? "\u{F012C}" : "\u{F0193}"
                    tooltipText: root.tr("save")
                    foreground: root.foreground
                    onClicked: root.act("save", row.index)
                  }

                  PanelActionButton {
                    iconText: "\u{F03EB}"
                    tooltipText: root.tr("edit")
                    foreground: root.foreground
                    onClicked: root.act("edit", row.index)
                  }

                  PanelActionButton {
                    iconText: "\u{F018F}"
                    tooltipText: root.tr("copy")
                    foreground: root.foreground
                    onClicked: root.act("copy", row.index)
                  }

                  PanelActionButton {
                    iconText: "\u{F0A7A}"
                    tooltipText: root.tr("remove")
                    foreground: root.foreground
                    hoverColor: Color.urgent
                    onClicked: root.act("delete", row.index)
                  }
                }
              }
            }
          }

          Item { width: 1; height: Style.space(14) }

          Text {
            width: parent.width
            leftPadding: root.inset
            rightPadding: root.inset
            text: root.tr("footer")
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Item { width: 1; height: Style.space(4) }
        }
      }
    }
  }
}
