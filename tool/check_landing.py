#!/usr/bin/env python3
"""Estructura de la landing estática: comprobaciones sin navegador.

La página es HTML y CSS puros, así que casi todo lo que puede romperse se
detecta leyendo los archivos: ids repetidos, anclajes que no llevan a
ninguna sección, clases del marcado sin regla en la hoja de estilos,
recursos externos que se cuelan y etiquetas mal cerradas.

Uso:
    python tool/check_landing.py [directorio]
Sale con código 0 si no hay problemas y 1 si encuentra alguno.
"""

from __future__ import annotations

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

VOID_TAGS = {"meta", "link", "br", "hr", "img", "input", "source", "area", "col"}


class LandingParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.ids: list[str] = []
        self.classes: set[str] = set()
        self.hrefs: list[str] = []
        self.srcs: list[str] = []
        self.scripts = 0
        self.images = 0
        self.stack: list[str] = []
        self.bad_closings: list[tuple[str, str]] = []

    def handle_starttag(self, tag: str, attrs) -> None:
        attributes = dict(attrs)
        if tag == "script":
            self.scripts += 1
        if tag == "img":
            self.images += 1
        if "id" in attributes:
            self.ids.append(attributes["id"])
        if "class" in attributes:
            self.classes.update(attributes["class"].split())
        if "href" in attributes:
            self.hrefs.append(attributes["href"])
        if "src" in attributes:
            self.srcs.append(attributes["src"])
        if tag not in VOID_TAGS:
            self.stack.append(tag)

    def handle_endtag(self, tag: str) -> None:
        if self.stack and self.stack[-1] == tag:
            self.stack.pop()
        elif tag in self.stack:
            self.bad_closings.append((tag, self.stack[-1]))
            self.stack.remove(tag)
        else:
            self.bad_closings.append((tag, "sin apertura"))


def check(directory: Path) -> list[str]:
    html = (directory / "index.html").read_text(encoding="utf-8")
    css = (directory / "styles.css").read_text(encoding="utf-8")

    parser = LandingParser()
    parser.feed(html)

    problems: list[str] = []

    duplicated = sorted({i for i in parser.ids if parser.ids.count(i) > 1})
    if duplicated:
        problems.append(f"ids duplicados: {duplicated}")

    if parser.stack:
        problems.append(f"etiquetas sin cerrar: {parser.stack}")
    if parser.bad_closings:
        problems.append(f"cierres inesperados: {parser.bad_closings}")

    if parser.scripts:
        problems.append(f"{parser.scripts} etiqueta(s) <script>: la pagina es sin JS")
    if parser.images:
        problems.append(f"{parser.images} <img>: los mockups son CSS, no imagenes")

    anchors = [h for h in parser.hrefs if h.startswith("#")]
    dangling = sorted({a[1:] for a in anchors if a != "#" and a[1:] not in parser.ids})
    if dangling:
        problems.append(f"anclajes sin destino: {dangling}")

    external = [u for u in parser.hrefs + parser.srcs
                if u.startswith(("http://", "https://", "//"))]
    if external:
        problems.append(f"recursos externos: {external}")

    declared = set(re.findall(r"\.([A-Za-z][\w-]*)", css))
    unstyled = sorted(parser.classes - declared)
    if unstyled:
        problems.append(f"clases del HTML sin regla CSS: {unstyled}")

    if css.count("{") != css.count("}"):
        problems.append(
            f"llaves desbalanceadas: {css.count('{')} abiertas vs {css.count('}')} cerradas")

    unused = sorted(declared - parser.classes)
    if unused:
        problems.append(f"aviso: reglas CSS sin uso en el marcado: {unused}")

    print(f"index.html: {len(html.splitlines())} lineas | "
          f"styles.css: {len(css.splitlines())} lineas")
    print(f"ids: {len(parser.ids)} | clases: {len(parser.classes)} | "
          f"anclajes internos: {len(anchors)}")
    return problems


def main() -> int:
    directory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("website")
    if not directory.is_dir():
        print(f"No existe el directorio: {directory}")
        return 1

    problems = check(directory)
    # "aviso:" es informativo; el resto son fallos.
    failures = [p for p in problems if not p.startswith("aviso:")]
    for problem in problems:
        print(f"  - {problem}")

    if failures:
        print(f"\nFALLO: {len(failures)} problema(s) estructural(es).")
        return 1
    print("\nOK: sin problemas estructurales.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
