#!/usr/bin/env python3
"""Estructura del sitio estático: comprobaciones sin navegador.

El sitio es HTML y CSS puros, así que casi todo lo que puede romperse se
detecta leyendo los archivos. El verificador analiza cada página `*.html`
del directorio (ids repetidos, etiquetas mal cerradas, anclajes rotos
—incluidos los cruces entre páginas—, clases del marcado sin regla en la
hoja de estilos, recursos externos y presupuesto de peso) y, cuando hay
más de una página, las comprobaciones de sitio completo: títulos,
descripciones, viewport, canonical, Open Graph, sitemap.xml, robots.txt
y coherencia de la navegación entre páginas.

Uso:
    python tool/check_landing.py [directorio]   # por defecto: website
Sale con código 0 si solo quedan avisos y 1 si encuentra algún problema.
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

# Presupuesto de peso: límite duro (fallo) y umbral de aviso, en bytes.
HTML_FAIL_BYTES = 40 * 1024
HTML_WARN_BYTES = 28 * 1024
CSS_FAIL_BYTES = 40 * 1024
CSS_WARN_BYTES = 32 * 1024

SITEMAP_NAME = "sitemap.xml"
ROBOTS_NAME = "robots.txt"
STYLESHEET_NAME = "styles.css"

VOID_TAGS = {"meta", "link", "br", "hr", "img", "input", "source", "area", "col"}

SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")


def kib(n_bytes: int) -> str:
    return f"{n_bytes / 1024:.1f} KiB"


class PageParser(HTMLParser):
    """Parsea una página y recolecta todo lo que luego se comprueba.

    El recorrido de atributos no depende de su orden: HTMLParser entrega
    cada atributo por separado, con comillas simples o dobles ya
    resueltas, así que `<nav class="x" aria-label="y">` y
    `<nav aria-label='y' class='x'>` se leen igual.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.classes: set[str] = set()
        self.hrefs: list[str] = []
        self.srcs: list[str] = []
        self.scripts = 0
        self.images = 0
        self.stack: list[str] = []
        self.bad_closings: list[tuple[str, str]] = []
        self.titles: list[str] = []
        self.metas: list[dict[str, str]] = []
        self.canonicals: list[str] = []
        self.navs: list[dict] = []  # {"classes": [...], "hrefs": [...]}
        self._in_title = False
        self._title_parts: list[str] = []
        self._nav_depth = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        attributes: dict[str, str] = {}
        for key, value in attrs:
            if key not in attributes:  # la primera aparición gana
                attributes[key] = value or ""
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
        if tag == "title":
            self._in_title = True
            self._title_parts = []
        if tag == "meta":
            self.metas.append(attributes)
        if tag == "link" and attributes.get("rel", "").strip().lower() == "canonical":
            self.canonicals.append(attributes.get("href", ""))
        if tag == "nav":
            self._nav_depth += 1
            self.navs.append({
                "classes": attributes.get("class", "").lower().split(),
                "hrefs": [],
            })
        elif self._nav_depth and self.navs and "href" in attributes:
            self.navs[-1]["hrefs"].append(attributes["href"])
        if tag not in VOID_TAGS:
            self.stack.append(tag)

    def handle_endtag(self, tag: str) -> None:
        if tag in VOID_TAGS:
            return  # tolera la sintaxis autocerrada <meta ... />
        if tag == "title" and self._in_title:
            self.titles.append("".join(self._title_parts))
            self._in_title = False
        elif tag == "nav" and self._nav_depth:
            self._nav_depth -= 1
        if self.stack and self.stack[-1] == tag:
            self.stack.pop()
        elif tag in self.stack:
            self.bad_closings.append((tag, self.stack[-1]))
            self.stack.remove(tag)
        else:
            self.bad_closings.append((tag, "sin apertura"))

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self._title_parts.append(data)

    def header_hrefs(self) -> list[str]:
        return list(self.navs[0]["hrefs"]) if self.navs else []

    def footer_hrefs(self) -> list[str]:
        out: list[str] = []
        for nav in self.navs:
            if any("footer" in cls for cls in nav["classes"]):
                out.extend(nav["hrefs"])
        return out


def meta_named(parser: PageParser, name: str) -> list[str]:
    return [m.get("content", "") for m in parser.metas
            if m.get("name", "").strip().lower() == name]


def og_named(parser: PageParser, prop: str) -> list[str]:
    return [m.get("content", "") for m in parser.metas
            if m.get("property", "").strip().lower() == prop]


def check_page(name: str, parser: PageParser, declared: set[str],
               parsers: dict[str, PageParser]) -> list[str]:
    """Comprobaciones que aplican a cada página por separado."""
    problems: list[str] = []

    duplicated = sorted({i for i in parser.ids if parser.ids.count(i) > 1})
    if duplicated:
        problems.append(f"{name}: ids duplicados: {duplicated}")

    if parser.stack:
        problems.append(f"{name}: etiquetas sin cerrar: {parser.stack}")
    if parser.bad_closings:
        problems.append(f"{name}: cierres inesperados: {parser.bad_closings}")

    if parser.scripts:
        problems.append(f"{name}: {parser.scripts} etiqueta(s) <script>: "
                        f"el sitio es sin JS")
    if parser.images:
        problems.append(f"{name}: {parser.images} <img>: los mockups son CSS, "
                        f"no imagenes")

    canonical_hrefs = set(parser.canonicals)
    external = sorted({u for u in parser.hrefs + parser.srcs
                       if u.startswith(("http://", "https://", "//"))
                       # el canonical debe ser absoluto por diseño; el resto
                       # de recursos cargados no pueden salir del sitio
                       and u not in canonical_hrefs})
    if external:
        problems.append(f"{name}: recursos externos: {external}")

    problems += check_links(name, parser, parsers)

    unstyled = sorted(parser.classes - declared)
    if unstyled:
        problems.append(f"{name}: clases del HTML sin regla CSS: {unstyled}")

    return problems


def check_links(name: str, parser: PageParser,
                parsers: dict[str, PageParser]) -> list[str]:
    """Enlaces internos: fragmentos locales y cruces entre páginas.

    ``#frag`` debe existir como id en la misma página; ``page.html`` y
    ``page.html#frag`` deben apuntar a un archivo del directorio y, con
    fragmento, a un id de esa página. Archivo ausente y fragmento colgado
    se informan por separado, citando la página ofendida.
    """
    dangling: list[str] = []
    missing: list[str] = []

    for href in parser.hrefs:
        if SCHEME_RE.match(href) or href.startswith("//"):
            continue  # externos y esquemas (mailto:, tel:): ya cubiertos
        target, _, frag = href.partition("#")
        if target.startswith("./"):
            target = target[2:]
        if not target:
            if frag and frag not in parser.ids:
                dangling.append(href)
            continue  # "#" a secas: no es un anclaje comprobable
        if not target.endswith(".html"):
            continue  # hoja de estilos, sitemap, etc.
        if target not in parsers:
            missing.append(href)
        elif frag and frag not in parsers[target].ids:
            dangling.append(href)

    problems: list[str] = []
    if missing:
        problems.append(f"{name}: enlaces a archivos que no existen: "
                        f"{sorted(set(missing))}")
    if dangling:
        problems.append(f"{name}: anclajes sin destino: {sorted(set(dangling))}")
    return problems


def analyze_page(path: Path) -> tuple[str, PageParser]:
    text = path.read_text(encoding="utf-8")
    parser = PageParser()
    parser.feed(text)
    return text, parser


def main() -> int:
    directory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("website")
    if not directory.is_dir():
        print(f"No existe el directorio: {directory}")
        return 1

    html_paths = sorted(p for p in directory.glob("*.html") if p.is_file())
    if not html_paths:
        print(f"No hay archivos HTML en: {directory}")
        return 1
    css_path = directory / STYLESHEET_NAME
    if not css_path.is_file():
        print(f"Falta {STYLESHEET_NAME} en: {directory}")
        return 1

    css_text = css_path.read_text(encoding="utf-8")
    declared = set(re.findall(r"\.([A-Za-z][\w-]*)", css_text))

    names = [p.name for p in html_paths]
    texts: dict[str, str] = {}
    parsers: dict[str, PageParser] = {}
    for path in html_paths:
        texts[path.name], parsers[path.name] = analyze_page(path)
    sizes = {p.name: p.stat().st_size for p in html_paths}
    lines = {name: len(texts[name].splitlines()) for name in texts}

    print(f"Verificando {directory}: {len(names)} pagina(s): {', '.join(sorted(names))}")

    # ── Resumen por página (peso: bytes y lineas) ─────────────────────
    for name in sorted(names):
        parser = parsers[name]
        anchors = sum(1 for h in parser.hrefs if h.startswith("#"))
        print(f"  {name}: {sizes[name]} bytes, {lines[name]} lineas | "
              f"{len(parser.ids)} ids, {len(parser.classes)} clases, "
              f"{anchors} anclajes internos")
    css_size = css_path.stat().st_size
    print(f"  {STYLESHEET_NAME}: {css_size} bytes, "
          f"{len(css_text.splitlines())} lineas")

    # ── Comprobaciones por página ─────────────────────────────────────
    problems: list[str] = []
    for name in sorted(names):
        problems += check_page(name, parsers[name], declared, parsers)

    # Clases CSS sin uso: se calcula sobre todas las páginas juntas.
    used = set().union(*(p.classes for p in parsers.values()))
    unused = sorted(declared - used)
    if unused:
        problems.append(f"aviso: reglas CSS sin uso en el marcado: {unused}")

    if css_text.count("{") != css_text.count("}"):
        problems.append(
            f"llaves desbalanceadas en {STYLESHEET_NAME}: "
            f"{css_text.count('{')} abiertas vs {css_text.count('}')} cerradas")

    # ── Presupuesto de peso ───────────────────────────────────────────
    for name in sorted(names):
        size = sizes[name]
        if size > HTML_FAIL_BYTES:
            problems.append(f"{name}: {kib(size)} supera el presupuesto duro "
                            f"de {HTML_FAIL_BYTES // 1024} KiB para una pagina")
        elif size > HTML_WARN_BYTES:
            problems.append(f"aviso: {name}: {kib(size)} supera el umbral de "
                            f"{HTML_WARN_BYTES // 1024} KiB para una pagina")
    if css_size > CSS_FAIL_BYTES:
        problems.append(f"{STYLESHEET_NAME}: {kib(css_size)} supera el "
                        f"presupuesto duro de {CSS_FAIL_BYTES // 1024} KiB")
    elif css_size > CSS_WARN_BYTES:
        problems.append(f"aviso: {STYLESHEET_NAME}: {kib(css_size)} supera el "
                        f"umbral de {CSS_WARN_BYTES // 1024} KiB")

    # ── Comprobaciones de sitio completo ──────────────────────────────
    if len(names) > 1:
        print(f"\nSitio completo: {len(names)} paginas - "
              f"comprobaciones cruzadas activas")
        problems += check_site_wide(directory, names, parsers)
    else:
        problems.append(
            "aviso: sitio de una sola pagina: se omiten las comprobaciones "
            "de sitio completo (titulos, metas, canonical, Open Graph, "
            f"{SITEMAP_NAME}, {ROBOTS_NAME} y navegacion)")

    # ── Resultado ─────────────────────────────────────────────────────
    # "aviso:" es informativo; el resto son fallos.
    failures = [p for p in problems if not p.startswith("aviso:")]
    for problem in problems:
        print(f"  - {problem}")

    if failures:
        print(f"\nFALLO: {len(failures)} problema(s) estructural(es).")
        return 1
    print("\nOK: sin problemas estructurales.")
    return 0


def check_site_wide(directory: Path, names: list[str],
                    parsers: dict[str, PageParser]) -> list[str]:
    """Solo con más de una página: metas, sitemap, robots y navegación."""
    problems: list[str] = []

    # ── Títulos ───────────────────────────────────────────────────────
    titles: dict[str, str] = {}
    for name in names:
        parser = parsers[name]
        if len(parser.titles) != 1:
            problems.append(f"{name}: debe tener exactamente un <title> "
                            f"(encontrados {len(parser.titles)})")
            continue
        title = parser.titles[0].strip()
        if not title:
            problems.append(f"{name}: <title> vacio")
            continue
        titles[name] = title
    by_title: dict[str, list[str]] = {}
    for name, title in titles.items():
        by_title.setdefault(title, []).append(name)
    for title, owners in sorted(by_title.items()):
        if len(owners) > 1:
            problems.append(f"titulo duplicado {title!r} en: {sorted(owners)}")

    # ── Meta description ──────────────────────────────────────────────
    descriptions: dict[str, str] = {}
    for name in names:
        found = meta_named(parsers[name], "description")
        if len(found) != 1:
            problems.append(f"{name}: debe tener exactamente una "
                            f"<meta name=\"description\"> (encontradas {len(found)})")
            continue
        if not found[0].strip():
            problems.append(f"{name}: <meta name=\"description\"> vacia")
            continue
        descriptions[name] = found[0].strip()
    by_desc: dict[str, list[str]] = {}
    for name, desc in descriptions.items():
        by_desc.setdefault(desc, []).append(name)
    for desc, owners in sorted(by_desc.items()):
        if len(owners) > 1:
            problems.append(f"description duplicada {desc!r} en: {sorted(owners)}")

    # ── Viewport ──────────────────────────────────────────────────────
    for name in names:
        count = len(meta_named(parsers[name], "viewport"))
        if count != 1:
            problems.append(f"{name}: debe tener exactamente una "
                            f"<meta name=\"viewport\"> (encontradas {count})")

    # ── Canonical ─────────────────────────────────────────────────────
    origins: set[str] = set()
    urls: dict[str, str] = {}
    for name in names:
        found = parsers[name].canonicals
        if len(found) != 1:
            problems.append(f"{name}: debe tener exactamente un "
                            f"<link rel=\"canonical\"> (encontrados {len(found)})")
            continue
        url = found[0].strip()
        parts = urlsplit(url)
        if not parts.scheme or not parts.netloc:
            problems.append(f"{name}: canonical no absoluto: {url!r}")
            continue
        origins.add(f"{parts.scheme}://{parts.netloc}")
        # El canonical tiene que ser la URL de esa misma pagina: si no se
        # comprueba la ruta, una copia mal pegada entre paginas pasa en
        # silencio y el sitemap se compara contra una URL inventada.
        expected_path = "/" if name == "index.html" else f"/{name}"
        if (parts.path or "/") != expected_path or parts.query or parts.fragment:
            problems.append(
                f"{name}: el canonical no apunta a esa misma pagina: {url!r} "
                f"(esperado ...{expected_path})")
            continue
        urls[name] = f"{parts.scheme}://{parts.netloc}{expected_path}"
    if len(origins) > 1:
        problems.append(f"origenes canonical distintos entre paginas: {sorted(origins)}")

    # ── Open Graph ────────────────────────────────────────────────────
    for name in names:
        for prop in ("og:title", "og:description", "og:type"):
            contents = og_named(parsers[name], prop)
            if not any(c.strip() for c in contents):
                problems.append(f"{name}: falta <meta property=\"{prop}\">")

    # ── Sitemap ───────────────────────────────────────────────────────
    sitemap_path = directory / SITEMAP_NAME
    if not sitemap_path.is_file():
        problems.append(f"falta {SITEMAP_NAME}")
    else:
        try:
            root = ET.fromstring(sitemap_path.read_bytes())
        except ET.ParseError as exc:
            problems.append(f"{SITEMAP_NAME} no es XML valido: {exc}")
        else:
            locs = {(el.text or "").strip() for el in root.iter()
                    if el.tag.split("}")[-1] == "loc" and (el.text or "").strip()}
            expected = set(urls.values())
            absent = sorted(expected - locs)
            extra = sorted(locs - expected)
            if absent:
                problems.append(f"paginas ausentes en {SITEMAP_NAME}: {absent}")
            if extra:
                problems.append(f"entradas de {SITEMAP_NAME} sin pagina: {extra}")

    # ── Robots ────────────────────────────────────────────────────────
    robots_path = directory / ROBOTS_NAME
    if not robots_path.is_file():
        problems.append(f"falta {ROBOTS_NAME}")
    else:
        sitemap_lines = [line for line
                         in robots_path.read_text(encoding="utf-8").splitlines()
                         if line.strip().lower().startswith("sitemap:")]
        if not sitemap_lines:
            problems.append(f"{ROBOTS_NAME} sin linea Sitemap:")
        else:
            url = sitemap_lines[0].split(":", 1)[1].strip()
            parts = urlsplit(url)
            ok_origin = (f"{parts.scheme}://{parts.netloc}" in origins
                         if parts.scheme and parts.netloc else False)
            if parts.path != f"/{SITEMAP_NAME}" or not ok_origin:
                problems.append(
                    f"{ROBOTS_NAME}: la linea Sitemap no apunta al "
                    f"{SITEMAP_NAME} del origen canonical: {url!r}")

    # ── Navegación coherente ──────────────────────────────────────────
    # La referencia es index.html cuando existe: es la pagina que
    # cualquiera lee como "la principal", y un aviso contra ella se
    # entiende sin pensarlo.
    reference = "index.html" if "index.html" in names else names[0]
    header_ref = parsers[reference].header_hrefs()
    footer_ref = parsers[reference].footer_hrefs()
    for name in names:
        if name == reference:
            continue
        if parsers[name].header_hrefs() != header_ref:
            problems.append(
                f"navegacion de cabecera distinta en {name}: esperado "
                f"{header_ref}, encontrado {parsers[name].header_hrefs()}")
            break
    for name in names:
        if name == reference:
            continue
        if parsers[name].footer_hrefs() != footer_ref:
            problems.append(
                f"navegacion de pie distinta en {name}: esperado "
                f"{footer_ref}, encontrado {parsers[name].footer_hrefs()}")
            break

    return problems


if __name__ == "__main__":
    raise SystemExit(main())
