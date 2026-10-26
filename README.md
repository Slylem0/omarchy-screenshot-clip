# Screenshot Clip for Omarchy

Print Screen copies to the clipboard instead of filling `~/Pictures`. Click the
notification to edit the screenshot, and save only the ones you want to keep.

*[Español más abajo](#español)*

## Why

Omarchy's Print Screen saves every capture as a PNG in `~/Pictures`, even the
ones you only meant to paste into a chat once. After a few weeks the folder is
full of screenshots nobody will open again.

## How it works

1. Press <kbd>Print</kbd> and select as usual: the screen freezes, <kbd>Space</kbd>
   snaps to a window, <kbd>F</kbd> takes the whole screen. It is Omarchy's own
   region picker, so selection behaves exactly like the stock screenshot.
2. The screenshot goes to the **clipboard**, ready for <kbd>Ctrl</kbd>+<kbd>V</kbd>.
   Nothing is written to `~/Pictures`.
3. A notification shows the thumbnail:
   - **Click** opens it in Tensaku. <kbd>Ctrl</kbd>+<kbd>S</kbd> saves it to
     `~/Pictures/screenshot-YYYY-MM-DD_HH-MM-SS.png`; <kbd>Enter</kbd> copies the
     edited image without saving a file.
   - **Right-click** closes the notification. It also goes away by itself after
     a few seconds.

The thumbnail comes from a temporary copy in `$XDG_RUNTIME_DIR/screenshot-clip/`,
which lives in RAM and is cleared on reboot. Only the 10 newest copies are kept.

Optical character recognition (<kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Print</kbd>)
and screen recording (<kbd>Alt</kbd>+<kbd>Print</kbd>) are not changed.

## Requirements

Omarchy with its stock screenshot tools: `grim`, `wl-copy`, `tensaku` and
`omarchy-capture-region`.

## Install

```bash
omarchy plugin add https://github.com/Slylem0/omarchy-screenshot-clip
```

Then bind Print Screen to it in `~/.config/hypr/bindings.lua`:

```lua
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot to clipboard", "~/.config/omarchy/plugins/slylem0.screenshot-clip/bin/screenshot-clip")
```

To go back to the stock behaviour, remove those two lines.

## Options

- `screenshot-clip [smart|region|windows|fullscreen]` picks the capture mode
  (default `smart`).
- `SCREENSHOT_CLIP_LANG=es` or `en` forces the notification language; by default
  it follows the system locale.
- Saved screenshots go where Omarchy's do: `$OMARCHY_SCREENSHOT_DIR`, else your
  XDG pictures folder.

## Tests

```bash
test/run
```

Runs the script against stubbed `grim`, `wl-copy`, Tensaku and notifier, so it
never touches your screen, clipboard or pictures folder, then validates the
manifest.

---

## Español

<kbd>Impr Pant</kbd> copia la captura al portapapeles en vez de llenar
`~/Pictures`. Con un clic en la notificación la editas y guardas solo las que
quieras conservar.

1. Presiona <kbd>Impr Pant</kbd> y selecciona como siempre (<kbd>Espacio</kbd>
   para una ventana, <kbd>F</kbd> para la pantalla completa).
2. La captura queda en el **portapapeles**. No se guarda nada en `~/Pictures`.
3. En la notificación:
   - **Clic**: abre Tensaku. <kbd>Ctrl</kbd>+<kbd>S</kbd> guarda en `~/Pictures`;
     <kbd>Enter</kbd> copia la imagen editada sin guardar archivo.
   - **Clic derecho**: cierra la notificación. También se va sola a los pocos
     segundos.

La miniatura sale de una copia temporal en la RAM (`$XDG_RUNTIME_DIR`), que se
borra al reiniciar. Para la instalación y el atajo, mira la sección *Install*.
Usa `SCREENSHOT_CLIP_LANG=es` para forzar los textos en español.

## License

MIT
