import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The floating card shown after a capture: thumbnail, Save / Edit / Close and a
// countdown line. Purely presentational; Service.qml owns the lifetime.
BorderSurface {
  id: root

  property string path: ""
  property string lang: "en"
  // "", "saving", "saved" or "failed"
  property string status: ""
  property real remaining: 1.0

  readonly property bool hovered: hover.hovered
  readonly property color text: Commons.Color.notifications.text
  readonly property color dim: Qt.darker(text, 1.4)
  readonly property string fontFamily: Style.font.family

  signal saveRequested()
  signal editRequested()
  signal closeRequested()

  function tr(key) { return Model.tr(root.lang, key) }

  implicitWidth: Style.space(340)
  implicitHeight: column.implicitHeight + borderTop + borderBottom
  radius: Style.cornerRadius
  color: Commons.Color.notifications.background
  borderSpec: Border.surfaceSpec("notifications", "border", Commons.Color.notifications.border, Math.max(1, Style.space(2)))
  clip: true

  HoverHandler { id: hover }

  // Right-click anywhere closes, like Omarchy's notifications.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onClicked: root.closeRequested()
  }

  ColumnLayout {
    id: column
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: root.borderTop
    anchors.leftMargin: root.borderLeft
    anchors.rightMargin: root.borderRight
    spacing: Style.space(8)

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Style.space(8)
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        text: root.status === "saved" ? "\u{F012C}" : root.status === "failed" ? "\u{F0028}" : "\u{F0E51}"
        textFormat: Text.PlainText
        color: root.status === "failed" ? Commons.Color.urgent : root.text
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Text {
        Layout.fillWidth: true
        text: root.status === "saved" ? root.tr("saved")
          : root.status === "failed" ? root.tr("saveFailed")
          : root.tr("copied")
        textFormat: Text.PlainText
        color: root.text
        font.family: "Liberation Sans"
        font.pixelSize: Style.font.title
        font.bold: true
        elide: Text.ElideRight
      }

      PanelActionButton {
        iconText: "\u{F0156}"
        tooltipText: root.tr("close")
        foreground: root.text
        onClicked: root.closeRequested()
      }
    }

    // Clicking the picture opens the editor, the same as the Edit button.
    Item {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      Layout.preferredHeight: Math.min(Style.space(190), thumb.implicitHeight > 0
        ? width * thumb.implicitHeight / Math.max(1, thumb.implicitWidth) : Style.space(120))

      Image {
        id: thumb
        anchors.fill: parent
        source: root.path ? Model.fileUrl(root.path) : ""
        sourceSize.width: Math.round(Style.space(340) * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        smooth: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.editRequested()
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      spacing: Style.space(8)

      Button {
        Layout.fillWidth: true
        iconText: "\u{F0193}"
        text: root.tr("save")
        bordered: true
        enabled: root.status === "" || root.status === "failed"
        opacity: enabled ? 1 : 0.5
        foreground: root.text
        onClicked: root.saveRequested()
      }

      Button {
        Layout.fillWidth: true
        iconText: "\u{F03EB}"
        text: root.tr("edit")
        bordered: true
        foreground: root.text
        onClicked: root.editRequested()
      }
    }

    // Countdown, drained by Service.qml and paused while the pointer is over the card.
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.max(1, Style.space(2))
      color: "transparent"

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * root.remaining
        color: Commons.Color.notifications.countdown
      }
    }
  }
}
