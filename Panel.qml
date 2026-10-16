import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar item and control popup for the iRocks K71M keyboard.
// The panel root doubles as the bar slot: it renders the BarIconButton and
// hosts the KeyboardPanel popup, shelling out to bin/k71m_ctrl.py.
Panel {
  id: root
  moduleName: "io.github.ryankuo.k71m"
  ipcTarget: "io.github.ryankuo.k71m"
  manageIpc: false

  property var anchorItem: null

  readonly property string scriptPath: Qt.resolvedUrl("bin/k71m_ctrl.py").toString().replace("file://", "")
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property string keyColor: "ffffff"
  property int keyR: 255
  property int keyG: 255
  property int keyB: 255
  property int keyLevel: 15
  property string keyEffect: "static"

  property string rimColor: "0000ff"
  property int rimR: 0
  property int rimG: 0
  property int rimB: 255
  property int rimLevel: 15
  property string rimEffect: "rim static"

  readonly property var baseColors: [
    { value: "ff0000", label: "Red" }, { value: "ff8000", label: "Orange" },
    { value: "ffff00", label: "Yellow" }, { value: "00ff00", label: "Green" },
    { value: "00ffff", label: "Cyan" }, { value: "0080ff", label: "Azure" },
    { value: "0000ff", label: "Blue" }, { value: "8000ff", label: "Purple" },
    { value: "ff00ff", label: "Magenta" }, { value: "ff0080", label: "Pink" },
    { value: "ffffff", label: "White" }, { value: "000000", label: "Off" }
  ]

  readonly property string keyCustomLabel: "Custom (" + root.keyR + ", " + root.keyG + ", " + root.keyB + ")"
  readonly property string rimCustomLabel: "Custom (" + root.rimR + ", " + root.rimG + ", " + root.rimB + ")"
  readonly property var keyColorOptions: root.baseColors.concat([{ value: "custom", label: root.keyCustomLabel }])
  readonly property var rimColorOptions: root.baseColors.concat([{ value: "custom", label: root.rimCustomLabel }])

  // Key-side onboard effects (modes 0..18).
  readonly property var keyEffectOptions: [
    { value: "static", label: "Static" }, { value: "singleon", label: "Single On" },
    { value: "singleoff", label: "Single Off" }, { value: "glittering", label: "Glittering" },
    { value: "falling", label: "Falling" }, { value: "colourful", label: "Colourful" },
    { value: "breath", label: "Breath" }, { value: "spectrum", label: "Spectrum" },
    { value: "outward", label: "Outward" }, { value: "scrolling", label: "Scrolling" },
    { value: "rolling", label: "Rolling" }, { value: "rotating", label: "Rotating" },
    { value: "explode", label: "Explode" }, { value: "launch", label: "Launch" },
    { value: "ripples", label: "Ripples" }, { value: "flowing", label: "Flowing" },
    { value: "pulsating", label: "Pulsating" }, { value: "tilt", label: "Tilt" },
    { value: "shuttle", label: "Shuttle" }
  ]

  // Rim-side effects (modes 19..25).
  readonly property var rimEffectOptions: [
    { value: "rim wave", label: "Wave" }, { value: "rim aurora", label: "Aurora" },
    { value: "rim snake", label: "Snake" }, { value: "rim spectrum", label: "Spectrum" },
    { value: "rim breathing1", label: "Breathing 1" }, { value: "rim breathing2", label: "Breathing 2" },
    { value: "rim static", label: "Static" }
  ]

  function h2(v) {
    var s = Math.round(Math.max(0, Math.min(255, v))).toString(16)
    return s.length < 2 ? "0" + s : s
  }
  function hexToRgb(h) {
    return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)]
  }

  function runK71m(args) {
    proc.command = ["python3", root.scriptPath].concat(args)
    proc.running = true
  }

  function applyKey() { root.runK71m(["set", root.h2(root.keyR) + root.h2(root.keyG) + root.h2(root.keyB), String(root.keyLevel)]) }
  function applyRim() { root.runK71m(["rim", root.h2(root.rimR) + root.h2(root.rimG) + root.h2(root.rimB), String(root.rimLevel)]) }

  function chooseKeyColor(v) {
    if (v === "custom") { root.keyColor = "custom"; return }
    var c = root.hexToRgb(v)
    root.keyR = c[0]; root.keyG = c[1]; root.keyB = c[2]
    root.keyColor = v
    root.applyKey()
  }

  function chooseRimColor(v) {
    if (v === "custom") { root.rimColor = "custom"; return }
    var c = root.hexToRgb(v)
    root.rimR = c[0]; root.rimG = c[1]; root.rimB = c[2]
    root.rimColor = v
    root.applyRim()
  }

  function setKeyLevel(v) { root.keyLevel = v; root.applyKey() }
  function setRimLevel(v) { root.rimLevel = v; root.applyRim() }

  function setKeyEffect(v) {
    root.keyEffect = v
    if (v === "static") root.applyKey()
    else root.runK71m(["effect", v, root.h2(root.keyR) + root.h2(root.keyG) + root.h2(root.keyB)])
  }

  function setRimEffect(v) {
    root.rimEffect = v
    if (v === "rim static") root.applyRim()
    else root.runK71m(["effect", v, root.h2(root.rimR) + root.h2(root.rimG) + root.h2(root.rimB)])
  }

  Process { id: proc }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌"
    slotSize: Style.bar.iconSlot
    tooltipText: "K71M RGB"
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.toggle()
    }
  }

  component RowLabel: Text {
    property string label: ""
    width: Style.space(72)
    height: Style.spacing.controlHeight
    verticalAlignment: Text.AlignVCenter
    text: label
    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
    font.family: root.fontFamily
    font.pixelSize: 12
  }

  component OptionRow: Row {
    id: row
    property string label: ""
    property string value: ""
    property var options: []
    property bool showDot: false
    property color dotColor: "transparent"
    signal picked(string value)
    width: parent.width
    spacing: Style.space(10)

    RowLabel { label: row.label }
    Dropdown {
      width: row.width - Style.space(82) - (row.showDot ? Style.space(26) : 0)
      label: ""
      showLabel: false
      value: row.value
      options: row.options
      foreground: root.fg
      fontFamily: root.fontFamily
      onChanged: function(value) { row.picked(value) }
    }
    Rectangle {
      visible: row.showDot
      width: Style.space(16)
      height: Style.space(16)
      radius: Style.space(8)
      color: row.dotColor
      border.width: 1
      border.color: Qt.rgba(0, 0, 0, 0.35)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  component RgbRow: Row {
    id: rgb
    property string label: ""
    property int value: 0
    signal picked(int value)
    width: parent.width
    spacing: Style.space(10)

    RowLabel { label: rgb.label; width: Style.space(20) }
    PanelSlider {
      width: rgb.width - Style.space(30)
      bar: root.bar
      minimum: 0
      maximum: 255
      step: 1
      integer: true
      value: rgb.value
      onReleased: function(value) { rgb.picked(Math.round(value)) }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem || button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(col.implicitHeight)

    Item {
      id: flick
      anchors.fill: parent

        Column {
        id: col
        width: parent.width
        spacing: Style.space(10)

        // ---- Keys ------------------------------------------------------
        PanelSectionHeader { text: "KEYS"; foreground: root.fg; fontFamily: root.fontFamily }
        OptionRow {
          label: "Effect"
          value: root.keyEffect
          options: root.keyEffectOptions
          onPicked: function(v) { root.setKeyEffect(v) }
        }
        OptionRow {
          label: "Colour"
          value: root.keyColor
          options: root.keyColorOptions
          showDot: root.keyColor === "custom"
          dotColor: "#" + root.h2(root.keyR) + root.h2(root.keyG) + root.h2(root.keyB)
          onPicked: function(v) { root.chooseKeyColor(v) }
        }
        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: root.keyColor === "custom"
          RgbRow { label: "R"; value: root.keyR; onPicked: function(v) { root.keyR = v; root.applyKey() } }
          RgbRow { label: "G"; value: root.keyG; onPicked: function(v) { root.keyG = v; root.applyKey() } }
          RgbRow { label: "B"; value: root.keyB; onPicked: function(v) { root.keyB = v; root.applyKey() } }
        }
        Row {
          width: parent.width
          spacing: Style.space(10)
          RowLabel { label: "Brightness" }
          PanelSlider {
            width: parent.width - Style.space(82)
            bar: root.bar
            minimum: 0
            maximum: 15
            step: 1
            integer: true
            tickCount: 16
            value: root.keyLevel
            onReleased: function(value) { root.setKeyLevel(Math.round(value)) }
          }
        }

        // ---- Outer rim -------------------------------------------------
        PanelSectionHeader { text: "RIM"; foreground: root.fg; fontFamily: root.fontFamily }
        OptionRow {
          label: "Effect"
          value: root.rimEffect
          options: root.rimEffectOptions
          onPicked: function(v) { root.setRimEffect(v) }
        }
        OptionRow {
          label: "Colour"
          value: root.rimColor
          options: root.rimColorOptions
          showDot: root.rimColor === "custom"
          dotColor: "#" + root.h2(root.rimR) + root.h2(root.rimG) + root.h2(root.rimB)
          onPicked: function(v) { root.chooseRimColor(v) }
        }
        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: root.rimColor === "custom"
          RgbRow { label: "R"; value: root.rimR; onPicked: function(v) { root.rimR = v; root.applyRim() } }
          RgbRow { label: "G"; value: root.rimG; onPicked: function(v) { root.rimG = v; root.applyRim() } }
          RgbRow { label: "B"; value: root.rimB; onPicked: function(v) { root.rimB = v; root.applyRim() } }
        }
        Row {
          width: parent.width
          spacing: Style.space(10)
          RowLabel { label: "Brightness" }
          PanelSlider {
            width: parent.width - Style.space(82)
            bar: root.bar
            minimum: 0
            maximum: 15
            step: 1
            integer: true
            tickCount: 16
            value: root.rimLevel
            onReleased: function(value) { root.setRimLevel(Math.round(value)) }
          }
        }

        Rectangle {
          width: offLabel.implicitWidth + Style.space(18)
          height: Style.space(26)
          radius: Style.space(7)
          color: offHover.containsMouse
            ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
            : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)

          Text {
            id: offLabel
            anchors.centerIn: parent
            text: "Turn Off"
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 12
          }

          MouseArea {
            id: offHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.runK71m(["off"])
          }
        }
      }
    }
  }
}
