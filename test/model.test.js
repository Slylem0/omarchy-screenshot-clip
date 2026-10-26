const assert = require("assert")
const Model = require("../Model.js")

const SCRIPT = "/home/u/.config/omarchy/plugins/slylem0.screenshot-clip/bin/screenshot-clip"

const cases = {
  "picks the language": () => {
    assert.strictEqual(Model.language("auto", "es_CO"), "es")
    assert.strictEqual(Model.language("auto", "en_US"), "en")
    assert.strictEqual(Model.language("es", "en_US"), "es")
    assert.strictEqual(Model.language("en", "es_ES"), "en")
    assert.strictEqual(Model.language("fr", "fr_FR"), "en")
    assert.strictEqual(Model.tr("es", "save"), "Guardar")
    assert.strictEqual(Model.tr("fr", "save"), "Save")
  },
  "every string exists in both languages": () => {
    assert.deepStrictEqual(Object.keys(Model.STRINGS.es).sort(), Object.keys(Model.STRINGS.en).sort())
  },
  "settings fall back to defaults": () => {
    assert.deepStrictEqual(Model.cleanSettings({}), {
      language: "auto", seconds: 6, keep: 10, takeOverPrint: true
    })
    assert.deepStrictEqual(Model.cleanSettings(null), Model.cleanSettings({}))
  },
  "settings are clamped and typed": () => {
    const s = Model.cleanSettings({ language: "es", seconds: 99, keep: 0, takeOverPrint: false })
    assert.deepStrictEqual(s, { language: "es", seconds: 30, keep: 1, takeOverPrint: false })
    const t = Model.cleanSettings({ language: "klingon", seconds: "x", keep: 7.6, takeOverPrint: "yes" })
    assert.deepStrictEqual(t, { language: "auto", seconds: 6, keep: 8, takeOverPrint: true })
  },
  "reads this plugin's entry from shell.json": () => {
    const config = JSON.stringify({
      bar: { layout: {
        left: [{ id: "omarchy.clock" }],
        right: [{ id: "slylem0.display-switch" }, { id: "slylem0.screenshot-clip", keep: 5, language: "es" }]
      } }
    })
    assert.deepStrictEqual(Model.settingsFromShellConfig(config, "slylem0.screenshot-clip"),
      { id: "slylem0.screenshot-clip", keep: 5, language: "es" })
  },
  "shell.json without the widget gives no settings": () => {
    assert.deepStrictEqual(Model.settingsFromShellConfig('{"bar":{"layout":{}}}', "slylem0.screenshot-clip"), {})
    assert.deepStrictEqual(Model.settingsFromShellConfig("not json", "slylem0.screenshot-clip"), {})
    assert.deepStrictEqual(Model.settingsFromShellConfig("", "slylem0.screenshot-clip"), {})
  },
  "binds Print Screen to the script with the settings": () => {
    const lua = Model.bindLua(SCRIPT, "es", 10)
    assert.ok(lua.indexOf('hl.unbind("PRINT")') === 0, lua)
    assert.ok(lua.indexOf(
      'o.bind("PRINT", "Screenshot to clipboard", "env SCREENSHOT_CLIP_LANG=es SCREENSHOT_CLIP_KEEP=10 \'' + SCRIPT + '\'")'
    ) > 0, lua)
  },
  "binding survives quotes and spaces in the path": () => {
    const lua = Model.bindLua("/home/a b/it's \"x\"\\bin/screenshot-clip", "en", 3)
    // Lua string: backslash and double quote escaped; shell: single quote closed and reopened.
    assert.ok(lua.indexOf("'/home/a b/it'\\\\''s \\\"x\\\"\\\\bin/screenshot-clip'") > 0, lua)
  },
  "restores the stock screenshot": () => {
    assert.strictEqual(Model.restoreLua(),
      'hl.unbind("PRINT")\no.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")')
  },
  "parses the recent list newest first": () => {
    const text = "/run/user/1000/screenshot-clip/screenshot-2026-10-25_21-57-42.png\n" +
      "/run/user/1000/screenshot-clip/screenshot-2026-10-25_09-05-01.png\n\n"
    const list = Model.parseList(text)
    assert.strictEqual(list.length, 2)
    assert.strictEqual(list[0].path, "/run/user/1000/screenshot-clip/screenshot-2026-10-25_21-57-42.png")
    assert.strictEqual(list[0].time, "21:57")
    assert.strictEqual(list[1].time, "09:05")
  },
  "recent list ignores names it does not understand": () => {
    const list = Model.parseList("/x/screenshot-weird.png\nrelative.png\n")
    assert.strictEqual(list.length, 1)
    assert.strictEqual(list[0].time, "")
  },
  "file url escapes the path": () => {
    assert.strictEqual(Model.fileUrl("/run/a b/#1.png"), "file:///run/a%20b/%231.png")
  }
}

let failed = 0
for (const [name, fn] of Object.entries(cases)) {
  try {
    fn()
    console.log("ok   " + name)
  } catch (e) {
    failed++
    console.log("FAIL " + name + ": " + e.message)
  }
}
process.exit(failed ? 1 : 0)
