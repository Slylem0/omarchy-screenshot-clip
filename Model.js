// Pure helpers shared by Service.qml, BarWidget.qml and Panel.qml. No QML
// imports, so the test runner can load this file under node as well.

var PLUGIN_ID = "slylem0.screenshot-clip"

var DEFAULTS = {
  language: "auto",
  seconds: 6,
  keep: 10,
  takeOverPrint: true
}

var STRINGS = {
  en: {
    copied: "Copied to clipboard",
    save: "Save",
    edit: "Edit",
    copy: "Copy",
    remove: "Delete",
    close: "Close",
    saved: "Saved to Pictures",
    saveFailed: "Could not save",
    recent: "Recent screenshots",
    recentMeta: "Only in memory until you save them",
    empty: "No screenshots yet. Press Print Screen.",
    tooltip: "Recent screenshots",
    footer: "Cleared on reboot. Saved ones go to Pictures."
  },
  es: {
    copied: "Copiada al portapapeles",
    save: "Guardar",
    edit: "Editar",
    copy: "Copiar",
    remove: "Borrar",
    close: "Cerrar",
    saved: "Guardada en Imágenes",
    saveFailed: "No se pudo guardar",
    recent: "Capturas recientes",
    recentMeta: "Solo en memoria hasta que las guardes",
    empty: "Aún no hay capturas. Presiona Impr Pant.",
    tooltip: "Capturas recientes",
    footer: "Se borran al reiniciar. Las guardadas van a Imágenes."
  }
}

function language(setting, locale) {
  if (setting === "es" || setting === "en") return setting
  return String(locale || "").indexOf("es") === 0 ? "es" : "en"
}

function tr(lang, key) {
  var table = STRINGS[lang] || STRINGS.en
  return table[key] !== undefined ? table[key] : STRINGS.en[key]
}

function clampInt(value, low, high, fallback) {
  var n = Number(value)
  if (value === null || value === undefined || value === "" || !isFinite(n)) return fallback
  return Math.max(low, Math.min(high, Math.round(n)))
}

function cleanSettings(raw) {
  var s = raw || {}
  return {
    language: s.language === "es" || s.language === "en" ? s.language : DEFAULTS.language,
    seconds: clampInt(s.seconds, 2, 30, DEFAULTS.seconds),
    keep: clampInt(s.keep, 1, 50, DEFAULTS.keep),
    takeOverPrint: s.takeOverPrint !== false
  }
}

// The bar widget's settings live inline in its shell.json bar entry. The
// service reads them from there so they apply even before the widget loads.
function settingsFromShellConfig(text, id) {
  var config
  try {
    config = JSON.parse(text)
  } catch (e) {
    return {}
  }
  var layout = config && config.bar && config.bar.layout
  if (!layout || typeof layout !== "object") return {}
  for (var section in layout) {
    var entries = layout[section]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      if (entries[i] && entries[i].id === id) return entries[i]
    }
  }
  return {}
}

function luaString(s) {
  return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
}

function shellQuote(s) {
  return "'" + String(s).replace(/'/g, "'\\''") + "'"
}

function bindLua(script, lang, keep) {
  var command = "env SCREENSHOT_CLIP_LANG=" + lang + " SCREENSHOT_CLIP_KEEP=" + keep + " " + shellQuote(script)
  return 'hl.unbind("PRINT")\no.bind("PRINT", "Screenshot to clipboard", ' + luaString(command) + ")"
}

// Same binding Omarchy ships in default/hypr/bindings/utilities.lua.
function restoreLua() {
  return 'hl.unbind("PRINT")\no.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")'
}

// `screenshot-clip list` prints one absolute path per line, newest first.
function parseList(text) {
  var lines = String(text || "").split("\n")
  var list = []
  for (var i = 0; i < lines.length; i++) {
    var path = lines[i].trim()
    if (path.charAt(0) !== "/") continue
    var m = /screenshot-\d{4}-\d{2}-\d{2}_(\d{2})-(\d{2})-\d{2}/.exec(path)
    list.push({ path: path, time: m ? m[1] + ":" + m[2] : "" })
  }
  return list
}

function fileUrl(path) {
  return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
}

if (typeof module !== "undefined") {
  module.exports = {
    PLUGIN_ID: PLUGIN_ID,
    DEFAULTS: DEFAULTS,
    STRINGS: STRINGS,
    language: language,
    tr: tr,
    cleanSettings: cleanSettings,
    settingsFromShellConfig: settingsFromShellConfig,
    bindLua: bindLua,
    restoreLua: restoreLua,
    parseList: parseList,
    fileUrl: fileUrl
  }
}
