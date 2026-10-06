#!/usr/bin/env python3
"""Pasada en dispositivo Android: driver sin dependencias.

Nació de una pasada real en la que el propio driver mintió dos veces, así que
esas dos lecciones están codificadas y no sólo documentadas:

1. `uiautomator dump` puede fallar y dejar en el teléfono el archivo ANTERIOR,
   con lo que recuperarlo devuelve un árbol viejo que parece estado fresco. Por
   eso se borra el archivo remoto antes de cada volcado y se verifica que el
   propio dump confirme que volcó.
2. El árbol puede ser de OTRA app (el launcher, o una app abierta por un toque
   perdido), y `adb shell input tap` **pierde eventos**. Nunca se concluye "la
   interfaz está congelada" desde un solo toque sintético: hay que reintentar y
   corroborar con el árbol, con el paquete en primer plano y con el logcat.

Uso:
    python tool/android_walkthrough.py focus
    python tool/android_walkthrough.py list
    python tool/android_walkthrough.py tap "Texto visible"
    python tool/android_walkthrough.py tap-at 540 2244
    python tool/android_walkthrough.py text
    python tool/android_walkthrough.py errors

`list` imprime el árbol de accesibilidad compacto: estado, centro, tamaño, clase
y texto. La geometría es la forma honesta de comprobar en el teléfono que un
widget es alcanzable, y el texto sirve para comparar el antes y el después de
cada toque.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "build" / "ui.xml"
APP = os.environ.get("TRAVELREADY_APP_ID", "com.buendidev.travel_ready")

REMOTE_DUMP = "/sdcard/walkthrough-ui.xml"

VOID = ""


def adb_path() -> str:
    local = os.environ.get("LOCALAPPDATA", "")
    candidates = [
        os.environ.get("ANDROID_HOME", ""),
        os.environ.get("ANDROID_SDK_ROOT", ""),
        os.path.join(local, "Android", "sdk") if local else "",
    ]
    for base in candidates:
        if base:
            exe = os.path.join(base, "platform-tools", "adb.exe")
            if os.path.isfile(exe):
                return exe
            exe = os.path.join(base, "platform-tools", "adb")
            if os.path.isfile(exe):
                return exe
    return "adb"  # que falle con un mensaje del sistema si no está en PATH


ADB = adb_path()


def sh(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([ADB, *args], capture_output=True, text=True)


def focused_package() -> str:
    out = sh("shell", "dumpsys", "window").stdout
    m = re.search(r"mCurrentFocus=Window\{[^}]*?\s(\S+?)/", out)
    return m.group(1) if m else "?"


def dump(wait: float = 0.0, require_app: bool = True) -> ET.Element:
    if wait:
        time.sleep(wait)
    last = ""
    for _attempt in range(4):
        sh("shell", "rm", "-f", REMOTE_DUMP)
        result = sh("shell", "uiautomator", "dump", REMOTE_DUMP)
        last = (result.stdout + result.stderr).strip()
        pulled = sh("pull", REMOTE_DUMP, str(CACHE))
        confirmed = "dumped to" in last or "hierchary dumped" in last
        if confirmed and "1 file pulled" in pulled.stdout + pulled.stderr:
            try:
                root = ET.parse(CACHE).getroot()
            except Exception:
                time.sleep(0.6)
                continue
            package = root.attrib.get("package") or next(
                (n.attrib.get("package") for n in root.iter("node")
                 if n.attrib.get("package")), VOID)
            if require_app and package != APP:
                print(f"AVISO: el arbol es de '{package or '?'}', no de la app. "
                      f"Primer plano: '{focused_package()}'.")
            return root
        time.sleep(0.6)
    raise SystemExit(f"volcado fallido o sin confirmar. Salida: {last!r}")


def center(bounds: str) -> tuple[int, int, int, int] | None:
    m = re.match(r"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]", bounds or VOID)
    if not m:
        return None
    x1, y1, x2, y2 = map(int, m.groups())
    if x2 <= x1 or y2 <= y1:
        return None
    return (x1 + x2) // 2, (y1 + y2) // 2, x2 - x1, y2 - y1


def items(root: ET.Element) -> list[tuple[str, tuple[int, int, int, int], bool, str]]:
    out = []
    for node in root.iter("node"):
        attrs = node.attrib
        text = (attrs.get("text") or "").strip() or (attrs.get("content-desc") or "").strip()
        box = center(attrs.get("bounds", VOID))
        if not box:
            continue
        clickable = attrs.get("clickable") == "true"
        if text or clickable:
            out.append((text, box, clickable, attrs.get("class", "").split(".")[-1]))
    return out


def main() -> int:
    command = sys.argv[1] if len(sys.argv) > 1 else "list"

    if command == "focus":
        print("primer plano:", focused_package())

    elif command == "list":
        for text, (x, y, w, h), clickable, cls in items(dump()):
            flag = "CLICK" if clickable else "     "
            print(f"{flag} ({x:5d},{y:5d}) {w:5d}x{h:<5d} {cls:<20} {text[:64]}")

    elif command == "text":
        for text, _box, _clickable, _cls in items(dump()):
            print(text[:90])

    elif command == "tap":
        needle = sys.argv[2]
        found = [i for i in items(dump()) if needle.lower() in i[0].lower() and i[2]]
        if not found:
            print("NO ENCONTRADO:", needle)
            return 2
        text, (x, y, _w, _h), _clickable, _cls = found[0]
        print(f"tap '{text[:40]}' @ ({x},{y})")
        sh("shell", "input", "tap", str(x), str(y))

    elif command == "tap-at":
        x, y = sys.argv[2], sys.argv[3]
        print(f"tap en ({x},{y})")
        sh("shell", "input", "tap", x, y)

    elif command == "errors":
        result = sh("logcat", "-d", "-s", "flutter:*")
        lines = [l for l in result.stdout.splitlines()
                 if re.search(r"exception|error", l, re.I)]
        for line in lines[-20:]:
            print(line)
        print(f"total de lineas con error: {len(lines)}")

    else:
        print(__doc__)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
