#!/usr/bin/env python3
"""Suite unittest de tool/check_landing.py.

Cada test monta un sitio minimo en un directorio temporal y llama al
punto de entrada real del verificador (``check_directory``): las reglas
no estan reimplementadas aqui, se comprueba el mensaje que sueltan.
Los ``aviso:`` son informativos y el resto son fallos, igual que en el
CLI. Solo biblioteca estandar y cero red: todo pasa leyendo archivos.
"""

from __future__ import annotations

import re
import struct
import subprocess
import tempfile
import unittest
import zlib
from pathlib import Path
from unittest import mock

import check_landing

ORIGIN = "https://travelready.example"

# Prosa de mas de 120 caracteres ya normalizada, para la regla de
# prosa repetida entre paginas.
LONG_PROSE = ("este parrafo largo existe unicamente para cruzar el umbral de "
              "ciento veinte caracteres de la regla de prosa repetida entre "
              "paginas del verificador estructural del sitio estatico.")

# Las cuatro paginas legales que la puerta de publicacion exige (R4)
# y que cada pagina debe enlazar (R5).
LEGAL_PAGES = ("aviso-legal.html", "privacidad.html", "terminos.html",
               "cookies.html")

# Aviso de borrador que el helper escribe en cada pagina legal.
# Corto a proposito: por debajo del umbral de 120 caracteres de la
# regla de prosa repetida entre paginas.
DRAFT_NOTICE = ('<p class="draft-notice">Texto juridico pendiente de '
                'revision: esta pagina todavia no esta en vigor.</p>')

# Bloque de enlaces legales que page() anade a cada pagina, fuera de
# cualquier nav para no mezclar con la regla de navegacion coherente.
LEGAL_LINKS = ('<p><a href="aviso-legal.html">Aviso legal</a> · '
               '<a href="privacidad.html">Privacidad</a> · '
               '<a href="terminos.html">Terminos</a> · '
               '<a href="cookies.html">Cookies</a></p>')


def canonical_url(name: str) -> str:
    """URL canonical que el verificador espera para esa pagina."""
    return f"{ORIGIN}/" if name == "index.html" else f"{ORIGIN}/{name}"


def png_bytes(width: int, height: int) -> bytes:
    """PNG minimo con la cabecera IHDR de las medidas pedidas.

    Al verificador solo le importa decodificar el IHDR: firma, chunk
    IHDR y IEND bastan. Sin bibliotecas externas.
    """
    ihdr = struct.pack(">II", width, height) + bytes([8, 6, 0, 0, 0])
    ihdr_chunk = (struct.pack(">I", len(ihdr)) + b"IHDR" + ihdr
                  + struct.pack(">I", zlib.crc32(b"IHDR" + ihdr)))
    iend_chunk = (struct.pack(">I", 0) + b"IEND"
                  + struct.pack(">I", zlib.crc32(b"IEND")))
    return b"\x89PNG\r\n\x1a\n" + ihdr_chunk + iend_chunk


def page(name: str, *, title: str | None = None, desc: str | None = None,
         h1: str | None = None, body: str = "", canonical: str | None = None,
         og: bool = True, viewport: bool = True, icon: bool = True,
         og_image: bool = True, legal_links: bool = True) -> str:
    """Pagina valida para las reglas de sitio completo.

    Solo lo imprescindible: titulo, description, viewport, canonical
    absoluto apuntando a la propia pagina, Open Graph con tarjeta
    social, icono local y un h1 unico. ``legal_links`` anade el bloque
    de enlaces a los cuatro textos legales (R5 lo exige en toda
    pagina). ``body`` anade justo el marcado que prueba la regla del
    test.
    """
    title = title if title is not None else f"Titulo de {name}"
    desc = desc if desc is not None else f"Descripcion unica de {name}"
    h1 = h1 if h1 is not None else f"Encabezado de {name}"
    canonical = canonical if canonical is not None else canonical_url(name)
    og_image_metas = (f'<meta property="og:image" content="{ORIGIN}/og-card.png">\n'
                      '<meta property="og:image:width" content="1200">\n'
                      '<meta property="og:image:height" content="630">\n'
                      f'<meta property="og:image:alt" content="Tarjeta de {name}">\n'
                      if og and og_image else "")
    og_metas = (f'<meta property="og:title" content="{title}">\n'
                f'<meta property="og:description" content="{desc}">\n'
                '<meta property="og:type" content="website">\n' if og else "")
    vp = '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    icon_link = ('<link rel="icon" href="favicon.svg" '
                 'type="image/svg+xml">\n' if icon else "")
    legal_block = LEGAL_LINKS + "\n" if legal_links else ""
    return f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
{vp}<title>{title}</title>
<meta name="description" content="{desc}">
<link rel="canonical" href="{canonical}">
{icon_link}{og_metas}{og_image_metas}</head>
<body>
<h1>{h1}</h1>
{body}
{legal_block}</body>
</html>
"""


def sitemap_xml(locs: list[str]) -> str:
    body = "".join(f"<url><loc>{loc}</loc></url>" for loc in locs)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
            f"{body}\n</urlset>\n")


def sitemap_for(names: list[str]) -> str:
    """Sitemap con las paginas dadas mas las cuatro legales del helper."""
    return sitemap_xml([canonical_url(n) for n in names + list(LEGAL_PAGES)])


def git(root: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True,
                   capture_output=True)


def make_git_repo(root: Path, *, gitignore: str | None = None,
                  add: list[str] | None = None) -> None:
    """Repositorio git de verdad dentro del directorio temporal.

    ``gitignore`` escribe un .gitignore antes de anadir; ``add`` anade
    archivos concretos uno a uno (por defecto, todo con -A).
    """
    if gitignore is not None:
        (root / ".gitignore").write_text(gitignore, encoding="utf-8")
    git(root, "init", "-q")
    if add is None:
        git(root, "add", "-A")
    else:
        for name in add:
            git(root, "add", name)


def write_site(directory: str, pages: dict[str, str], *,
               css: str = "body{margin:0}\n",
               sitemap: str | None | bool = None,
               robots: str | None | bool = None,
               git: bool | str = True,
               legal: bool = True) -> Path:
    """Escribe el sitio y devuelve la ruta del directorio.

    ``sitemap`` y ``robots`` en None se generan correctos para las
    paginas dadas; ``False`` los omite y un str se escribe tal cual,
    para poder probar sus reglas. ``git`` monta un repositorio de
    verdad con todo rastreado (el caso real); un str es el contenido
    del .gitignore (para los fixtures de archivos ignorados) y False
    deja el directorio sin repositorio. ``legal`` anade las cuatro
    paginas legales con su aviso de borrador y su regla CSS: R4 y R5
    son incondicionales, asi que todo sitio de prueba las lleva;
    ``False`` las omite para probar la propia puerta. Las paginas
    legales heredan los <nav> de index.html para no despertar la
    regla de navegacion coherente en los fixtures que construyen
    navegacion a mano.
    """
    root = Path(directory)
    pages = dict(pages)
    if legal:
        navs = "\n".join(re.findall(r"<nav\b.*?</nav>",
                                    pages.get("index.html", ""), re.S))
        for name in LEGAL_PAGES:
            pages.setdefault(name, page(name, body=navs + DRAFT_NOTICE))
        if ".draft-notice" not in css:
            css += ".draft-notice{margin:0}\n"
    for name, html in pages.items():
        (root / name).write_text(html, encoding="utf-8")
    (root / check_landing.STYLESHEET_NAME).write_text(css, encoding="utf-8")
    (root / "favicon.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg"></svg>\n', encoding="utf-8")
    (root / "og-card.png").write_bytes(png_bytes(1200, 630))
    if sitemap is None:
        sitemap = sitemap_xml([canonical_url(n) for n in pages])
    if sitemap is not False:
        (root / check_landing.SITEMAP_NAME).write_text(sitemap,
                                                       encoding="utf-8")
    if robots is None:
        robots = f"Sitemap: {ORIGIN}/{check_landing.SITEMAP_NAME}\n"
    if robots is not False:
        (root / check_landing.ROBOTS_NAME).write_text(robots,
                                                      encoding="utf-8")
    if git is not False:
        make_git_repo(root,
                      gitignore=git if isinstance(git, str) else None)
    return root


def run_checker(root: Path) -> list[str]:
    problems, _info = check_landing.check_directory(root)
    return problems


def failures(problems: list[str]) -> list[str]:
    """Los problemas que hacen salir 1, mismo criterio que el CLI."""
    return [p for p in problems if not p.startswith("aviso:")]


class CheckerTestCase(unittest.TestCase):
    """Base con directorio temporal y asertos sobre mensajes."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)

    def assertSingleFailure(self, problems: list[str], expected: str) -> None:
        """El sitio falla, y por lo que se pide, citando el mensaje."""
        self.maxDiff = None
        joined = "\n".join(problems)
        self.assertIn(expected, joined)
        self.assertEqual(len(failures(problems)), 1,
                         f"fallos inesperados: {failures(problems)}")


class CleanSiteTest(CheckerTestCase):
    """El caso que pasa: dos paginas mas las cuatro legales del helper."""

    def test_clean_two_page_site_has_no_problems(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])


class IconTest(CheckerTestCase):
    """R1: exactamente un <link rel="icon">, local y con archivo.

    Un sitio de una pagina basta: la regla es por pagina, no de sitio
    completo.
    """

    def test_one_local_icon_passes(self) -> None:
        root = write_site(str(self.root),
                          {"index.html": page("index.html")})
        # La regla del icono es por pagina: no depende de las
        # comprobaciones de sitio completo.
        self.assertEqual(failures(run_checker(root)), [])

    def test_missing_icon_fails(self) -> None:
        root = write_site(str(self.root),
                          {"index.html": page("index.html", icon=False)})
        self.assertSingleFailure(run_checker(root),
                                 'index.html: falta el <link rel="icon">')

    def test_two_icons_fail(self) -> None:
        html = page("index.html",
                    body='<link rel="icon" href="favicon.svg">')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: debe tener exactamente un '
            '<link rel="icon"> (encontrados 2)')

    def test_remote_icon_fails(self) -> None:
        # Un icono remoto enciende tambien la regla de recursos externos:
        # dos fallos, el segundo es el de esta regla.
        html = page("index.html").replace(
            'href="favicon.svg"', 'href="https://cdn.example/favicon.svg"')
        root = write_site(str(self.root), {"index.html": html})
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn('el <link rel="icon"> debe ser una ruta local, no '
                      "'https://cdn.example/favicon.svg'", joined)
        self.assertEqual(len(failures(problems)), 2, joined)

    def test_icon_to_missing_file_fails(self) -> None:
        html = page("index.html").replace(
            'href="favicon.svg"', 'href="ausente.svg"')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: el <link rel="icon"> apunta a un archivo que no '
            "existe: 'ausente.svg'")


class OgImageTest(CheckerTestCase):
    """R2: la tarjeta social.

    Exactamente una og:image, absoluta y en el origen del canonical, que
    resuelva a un PNG de 1200x630 del sitio, con width/height que
    coincidan con el raster y un alt presente y no vacio.
    """

    def test_social_card_passes(self) -> None:
        root = write_site(str(self.root),
                          {"index.html": page("index.html")})
        self.assertEqual(failures(run_checker(root)), [])

    def test_missing_og_image_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html", og_image=False)})
        self.assertSingleFailure(run_checker(root),
                                 'index.html: falta <meta property="og:image">')

    def test_two_og_images_fail(self) -> None:
        extra = f'<meta property="og:image" content="{ORIGIN}/og-card.png">'
        html = page("index.html", body=extra)
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: debe tener exactamente una '
            '<meta property="og:image"> (encontradas 2)')

    def test_foreign_origin_og_image_fails(self) -> None:
        html = page("index.html").replace(
            f'content="{ORIGIN}/og-card.png"',
            'content="https://otro.example/og-card.png"')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            "index.html: og:image fuera del origen del canonical: "
            "'https://otro.example/og-card.png'")

    def test_og_image_outside_site_fails(self) -> None:
        html = page("index.html").replace(
            f'content="{ORIGIN}/og-card.png"',
            f'content="{ORIGIN}/../fuera.png"')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            "index.html: og:image sale del directorio del sitio: "
            f"'{ORIGIN}/../fuera.png'")

    def test_og_image_missing_file_fails(self) -> None:
        html = page("index.html").replace(
            f'content="{ORIGIN}/og-card.png"',
            f'content="{ORIGIN}/fantasma.png"')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            "index.html: og:image apunta a un archivo que no existe: "
            f"'{ORIGIN}/fantasma.png'")

    def test_wrong_dimensions_fail(self) -> None:
        # El raster mide otra cosa y las metas lo cuentan igual: solo
        # falla la regla de dimensiones. El raster es uno para todo el
        # sitio, asi que el mismo fallo canta en las paginas legales
        # del helper; todos los fallos son de esta regla.
        root = write_site(str(self.root),
                          {"index.html": page("index.html")})
        (root / "og-card.png").write_bytes(png_bytes(800, 418))
        html = page("index.html").replace(
            'content="1200"', 'content="800"').replace(
            'content="630"', 'content="418"')
        (root / "index.html").write_text(html, encoding="utf-8")
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("index.html: la imagen de og:image mide 800x418, "
                      "se requiere 1200x630", joined)
        for failure in failures(problems):
            self.assertIn("og:image", failure)

    def test_width_meta_disagreeing_with_raster_fails(self) -> None:
        html = page("index.html").replace(
            '<meta property="og:image:width" content="1200">',
            '<meta property="og:image:width" content="900">')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            "index.html: <meta property=\"og:image:width\"> dice '900', "
            "la imagen mide 1200")

    def test_height_meta_disagreeing_with_raster_fails(self) -> None:
        html = page("index.html").replace(
            '<meta property="og:image:height" content="630">',
            '<meta property="og:image:height" content="500">')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            "index.html: <meta property=\"og:image:height\"> dice '500', "
            "la imagen mide 630")

    def test_missing_width_meta_fails(self) -> None:
        html = page("index.html").replace(
            '<meta property="og:image:width" content="1200">\n', "")
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: falta <meta property="og:image:width">')

    def test_missing_alt_fails(self) -> None:
        html = page("index.html").replace(
            '<meta property="og:image:alt" content="Tarjeta de index.html">\n',
            "")
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: falta <meta property="og:image:alt">')

    def test_empty_alt_fails(self) -> None:
        html = page("index.html").replace(
            'content="Tarjeta de index.html"', 'content=" "')
        root = write_site(str(self.root), {"index.html": html})
        self.assertSingleFailure(
            run_checker(root),
            'index.html: <meta property="og:image:alt"> vacia')


class PageRulesTest(CheckerTestCase):
    """Reglas por pagina.

    El helper anade las cuatro paginas legales a todo sitio, asi que
    las comprobaciones cruzadas de sitio completo estan activas; los
    fixtures siguen construidos para que cada fallo tenga una sola
    causa posible.
    """

    def test_page_without_script_or_img_passes(self) -> None:
        root = write_site(str(self.root),
                          {"index.html": page("index.html")})
        self.assertEqual(failures(run_checker(root)), [])

    def test_single_page_site_announces_omitted_cross_checks(self) -> None:
        # Sin las paginas legales (legal=False) el sitio de prueba
        # vuelve a una sola pagina: el verificador lo anuncia con su
        # aviso de siempre, junto a los fallos de la puerta legal.
        root = write_site(str(self.root),
                          {"index.html": page("index.html")}, legal=False)
        problems = run_checker(root)
        self.assertTrue(any("sitio de una sola pagina" in p
                            for p in problems))

    def test_script_tag_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body="<script>alert('hola')</script>"),
        })
        self.assertSingleFailure(run_checker(root), "etiqueta(s) <script>")

    def test_img_tag_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html", body='<img src="foto.png">'),
        })
        self.assertSingleFailure(run_checker(root), "<img>: los mockups")

    def test_broken_internal_link_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<a href="ausente.html">x</a>'),
        })
        self.assertSingleFailure(run_checker(root),
                                 "enlaces a archivos que no existen: "
                                 "['ausente.html']")

    def test_internal_link_to_existing_page_passes(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<a href="otra.html">x</a>'),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])

    def test_dangling_fragment_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html", body='<a href="#nadie">x</a>'),
        })
        self.assertSingleFailure(run_checker(root),
                                 "anclajes sin destino: ['#nadie']")

    def test_fragment_to_existing_id_passes(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<a href="#top">x</a>'
                                    '<div id="top">destino</div>'),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])

    def test_external_resource_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page(
                "index.html",
                body='<a href="https://cdn.example/app.css">x</a>'),
        })
        self.assertSingleFailure(run_checker(root),
                                 "recursos externos: "
                                 "['https://cdn.example/app.css']")

    def test_absolute_canonical_is_not_reported_as_external(self) -> None:
        # Con dos paginas el sitio queda del todo callado: con una sola
        # habria el aviso disenyado de "sitio de una sola pagina".
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])

    def test_duplicate_id_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<div id="x"></div><div id="x"></div>'),
        })
        self.assertSingleFailure(run_checker(root), "ids duplicados: ['x']")

    def test_unclosed_tag_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html", body="<div><p>texto</p>"),
        })
        problems = run_checker(root)
        joined = "\n".join(problems)
        # Un div abierto arrastra dos mensajes del mismo grupo de reglas:
        # el div sin cerrar y los cierres de body/html que ya no
        # emparejan. Ninguna otra regla entra.
        self.assertIn("etiquetas sin cerrar: ['div']", joined)
        for failure in failures(problems):
            self.assertIn("index.html:", failure)
            self.assertRegex(
                failure, "etiquetas sin cerrar|cierres inesperados")

    def test_unstyled_class_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<p class="sinregla">texto</p>'),
        })
        self.assertSingleFailure(run_checker(root),
                                 "clases del HTML sin regla CSS: ['sinregla']")

    def test_class_declared_in_css_passes(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<p class="conregla">texto</p>'),
            "otra.html": page("otra.html"),
        }, css="body{margin:0}\n.conregla{color:red}\n")
        self.assertEqual(run_checker(root), [])

    def test_two_header_lists_with_different_hrefs_fail(self) -> None:
        # El nav de cabecera lleva varias listas identicas (disclosure y
        # escritorio); separar sus enlaces debe cantar. Los hrefs apuntan
        # a la propia pagina para no mezclar la regla de enlaces. La
        # regla es por pagina y las legales del helper heredan el nav:
        # el mismo fallo canta en cada una, y ninguno de otro tipo.
        nav = ('<nav><ul><li><a href="index.html">A</a></li></ul>'
               '<ul><li><a href="#">B</a></li></ul></nav>')
        root = write_site(str(self.root),
                          {"index.html": page("index.html", body=nav)})
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("la lista de enlaces 2 de la cabecera no "
                      "coincide con la primera: esperado "
                      "['index.html'], encontrado ['#']", joined)
        for failure in failures(problems):
            self.assertIn("de la cabecera no coincide con la primera",
                          failure)

    def test_two_header_lists_with_different_current_fail(self) -> None:
        nav = ('<nav><ul><li><a href="index.html">A</a></li></ul>'
               '<ul><li><a aria-current="page" href="index.html">B</a>'
               '</li></ul></nav>')
        root = write_site(str(self.root),
                          {"index.html": page("index.html", body=nav)})
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("aria-current de la lista 2 de la cabecera "
                      "no coincide con la primera", joined)
        for failure in failures(problems):
            self.assertIn("de la cabecera no coincide con la primera",
                          failure)

    def test_two_identical_header_lists_pass(self) -> None:
        nav = ('<nav><ul><li><a href="index.html">A</a></li></ul>'
               '<ul><li><a href="index.html">A</a></li></ul></nav>')
        root = write_site(str(self.root),
                          {"index.html": page("index.html", body=nav)})
        self.assertEqual(failures(run_checker(root)), [])


class BudgetTest(CheckerTestCase):
    """Presupuesto de bytes: aviso por debajo del duro, fallo por encima."""

    def pad_html(self, text: str, target: int) -> str:
        # Un comentario HTML: bytes sin marcado comprobable.
        filler = "<!-- " + "a" * 1024 + " -->\n"
        while len(text.encode("utf-8")) <= target:
            text += filler
        return text

    def pad_css(self, text: str, target: int) -> str:
        filler = "/* " + "a" * 1024 + " */\n"
        while len(text.encode("utf-8")) <= target:
            text += filler
        return text

    def test_html_over_warn_is_only_a_warning(self) -> None:
        big = self.pad_html(page("index.html"),
                            check_landing.HTML_WARN_BYTES + 1)
        self.assertGreater(len(big.encode("utf-8")),
                           check_landing.HTML_WARN_BYTES)
        self.assertLessEqual(len(big.encode("utf-8")),
                             check_landing.HTML_FAIL_BYTES)
        root = write_site(str(self.root), {"index.html": big})
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("aviso: index.html:", joined)
        self.assertIn("supera el umbral de 28 KiB", joined)
        self.assertEqual(failures(problems), [])

    def test_html_over_hard_budget_fails(self) -> None:
        big = self.pad_html(page("index.html"),
                            check_landing.HTML_FAIL_BYTES + 1)
        self.assertGreater(len(big.encode("utf-8")),
                           check_landing.HTML_FAIL_BYTES)
        root = write_site(str(self.root), {"index.html": big})
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("index.html:", joined)
        self.assertIn("supera el presupuesto duro de 40 KiB", joined)
        self.assertEqual(len(failures(problems)), 1)

    def test_css_over_warn_is_only_a_warning(self) -> None:
        big = self.pad_css("body{margin:0}\n",
                           check_landing.CSS_WARN_BYTES + 1)
        self.assertLessEqual(len(big.encode("utf-8")),
                             check_landing.CSS_FAIL_BYTES)
        root = write_site(str(self.root),
                          {"index.html": page("index.html")}, css=big)
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("aviso: styles.css:", joined)
        self.assertIn("supera el umbral de 32 KiB", joined)
        self.assertEqual(failures(problems), [])

    def test_css_over_hard_budget_fails(self) -> None:
        big = self.pad_css("body{margin:0}\n",
                           check_landing.CSS_FAIL_BYTES + 1024)
        root = write_site(str(self.root),
                          {"index.html": page("index.html")}, css=big)
        problems = run_checker(root)
        joined = "\n".join(problems)
        self.assertIn("styles.css:", joined)
        self.assertIn("supera el presupuesto duro de 40 KiB", joined)
        self.assertEqual(len(failures(problems)), 1)

    def test_under_budget_is_quiet(self) -> None:
        # Varias paginas (el helper anade las legales): sin avisos de
        # presupuesto ni de nada mas.
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])


class GitTrackingTest(CheckerTestCase):
    """R3: lo referenciado y lo listado en el sitemap, rastreado por git.

    La leccion que costo una release: website/robots.txt quedaba fuera
    del repositorio por un *.txt en el .gitignore, cada ejecucion local
    pasaba y un clon limpio habria fallado. Los fixtures montan un
    repositorio git de verdad dentro del directorio temporal.
    """

    def site_with_notes(self, *, gitignore: str | None = None) -> Path:
        root = write_site(str(self.root), {
            "index.html": page("index.html",
                               body='<a href="notas.txt">notas</a>')},
            git=False)
        (root / "notas.txt").write_text("notas\n", encoding="utf-8")
        make_git_repo(root, gitignore=gitignore)
        return root

    def test_tracked_referenced_files_pass(self) -> None:
        root = self.site_with_notes()
        problems = run_checker(root)
        self.assertEqual(failures(problems), [])
        # y sin aviso de git: el repositorio existe y esta entero
        self.assertFalse(any("git" in p for p in problems), problems)

    def test_ignored_referenced_file_fails(self) -> None:
        # notas.txt existe, esta referenciado y el *.txt del .gitignore
        # lo deja fuera del indice: exactamente la trampa de robots.txt.
        root = self.site_with_notes(gitignore="*.txt\n")
        self.assertSingleFailure(
            run_checker(root),
            "archivo referenciado pero no rastreado por git: 'notas.txt'")

    def test_sitemap_page_untracked_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html")}, git=False)
        make_git_repo(root, add=["index.html", "aviso-legal.html",
                                 "privacidad.html", "terminos.html",
                                 "cookies.html", "sitemap.xml", "robots.txt",
                                 "styles.css", "favicon.svg", "og-card.png"])
        self.assertSingleFailure(
            run_checker(root),
            "pagina listada en sitemap.xml pero no rastreada por git: "
            "'otra.html'")

    def test_not_a_git_repo_emits_aviso_and_skips(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html")}, git=False)
        problems = run_checker(root)
        self.assertEqual(failures(problems), [])
        joined = "\n".join(problems)
        self.assertIn("aviso: se omite la comprobacion de archivos no "
                      "rastreados por git:", joined)

    def test_git_absent_emits_aviso_and_skips(self) -> None:
        # El sitio de produccion se comprueba en maquinas sin git: la
        # ausencia del binario no puede tumbar la verificacion.
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html")})
        with mock.patch.object(check_landing.subprocess, "run",
                               side_effect=FileNotFoundError("git")):
            problems = run_checker(root)
        self.assertEqual(failures(problems), [])
        joined = "\n".join(problems)
        self.assertIn("aviso: se omite la comprobacion de archivos no "
                      "rastreados por git:", joined)


class LegalDraftTest(CheckerTestCase):
    """R4: puerta de publicacion de los cuatro textos legales.

    Los textos legales se publican como borradores mientras el
    abogado no los apruebe y el titular no rellene en ellos sus datos
    de identidad. Esta regla es deliberadamente temporal: mientras el
    aviso de borrador este en las paginas, la puerta exige que cada
    texto exista y lo lleve exactamente una vez y con texto, de modo
    que ningun borrador pueda publicarse como si estuviera en vigor;
    cuando los textos se aprueben y los datos del titular esten, el
    aviso se retira y esta regla se sustituye a proposito por la que
    corresponda comprobar entonces.
    """

    def test_draft_legal_pages_pass(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])

    def test_missing_legal_page_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        }, legal=False)
        joined = "\n".join(run_checker(root))
        for name in LEGAL_PAGES:
            with self.subTest(pagina=name):
                self.assertIn(f"falta la pagina legal {name}", joined)

    def test_legal_page_without_notice_fails(self) -> None:
        # La pagina cookies se construye a mano sin aviso; el helper
        # respeta la pagina dada y completa las otras tres.
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
            "cookies.html": page("cookies.html"),
        })
        self.assertSingleFailure(
            run_checker(root),
            'cookies.html: falta el aviso de borrador '
            '<p class="draft-notice">')

    def test_legal_page_with_empty_notice_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
            "cookies.html": page(
                "cookies.html", body='<p class="draft-notice"> </p>'),
        })
        self.assertSingleFailure(
            run_checker(root),
            'cookies.html: el <p class="draft-notice"> está vacío')

    def test_legal_page_with_two_notices_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
            "cookies.html": page(
                "cookies.html", body=DRAFT_NOTICE + DRAFT_NOTICE),
        })
        self.assertSingleFailure(
            run_checker(root),
            'cookies.html: debe tener exactamente un '
            '<p class="draft-notice"> (encontrados 2)')


class LegalLinksTest(CheckerTestCase):
    """R5: cada pagina enlaza los cuatro textos legales.

    Una pagina nueva no puede publicarse sin los enlaces legales y un
    enlace retirado falla la puerta. La regla mira los href de cada
    pagina sin importar donde cuelguen (nav del pie, parrafo propio o
    bloque aparte), asi que no depende de la copia del sitio.
    """

    def test_pages_link_the_legal_pages(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html"),
            "otra.html": page("otra.html"),
        })
        self.assertEqual(run_checker(root), [])

    def test_page_without_legal_links_fails(self) -> None:
        root = write_site(str(self.root), {
            "index.html": page("index.html", legal_links=False),
            "otra.html": page("otra.html"),
        })
        self.assertSingleFailure(
            run_checker(root),
            "index.html: faltan enlaces a las paginas legales: "
            "['aviso-legal.html', 'privacidad.html', 'terminos.html', "
            "'cookies.html']")

    def test_page_missing_one_legal_link_fails(self) -> None:
        html = page("index.html").replace(
            '<a href="cookies.html">Cookies</a>', "")
        root = write_site(str(self.root), {
            "index.html": html,
            "otra.html": page("otra.html"),
        })
        self.assertSingleFailure(
            run_checker(root),
            "index.html: faltan enlaces a las paginas legales: "
            "['cookies.html']")


class SiteWideTest(CheckerTestCase):
    """Reglas de sitio completo: siempre dos paginas validas de base."""

    def two_pages(self, **overrides) -> tuple[Path, dict[str, str]]:
        index = page("index.html", **overrides.get("index", {}))
        otra = page("otra.html", **overrides.get("otra", {}))
        root = write_site(str(self.root), {
            "index.html": index,
            "otra.html": otra,
        }, css=overrides.get("css", "body{margin:0}\n"),
            sitemap=overrides.get("sitemap"), robots=overrides.get("robots"))
        return root, {"index.html": index, "otra.html": otra}

    # ── titulo y description ────────────────────────────────────────

    def test_unique_title_and_description_pass(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    def test_duplicate_title_fails(self) -> None:
        root, _ = self.two_pages(index={"title": "Igual"},
                                 otra={"title": "Igual"})
        self.assertSingleFailure(run_checker(root),
                                 "titulo duplicado 'Igual' en: "
                                 "['index.html', 'otra.html']")

    def test_missing_title_fails(self) -> None:
        html = page("otra.html").replace("<title>Titulo de otra.html</title>",
                                         "")
        root = write_site(str(self.root), {
            "index.html": page("index.html"), "otra.html": html})
        self.assertSingleFailure(run_checker(root),
                                 "otra.html: debe tener exactamente un "
                                 "<title> (encontrados 0)")

    def test_duplicate_description_fails(self) -> None:
        root, _ = self.two_pages(index={"desc": "Misma descripción"},
                                 otra={"desc": "Misma descripción"})
        self.assertSingleFailure(run_checker(root),
                                 "description duplicada 'Misma descripción' "
                                 "en: ['index.html', 'otra.html']")

    # ── h1 y jerarquia de encabezados ────────────────────────────────

    def test_exactly_one_h1_per_page_passes(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    def test_two_h1_on_a_page_fails(self) -> None:
        root, _ = self.two_pages(
            otra={"body": "<h1>Segundo</h1>"})
        self.assertSingleFailure(run_checker(root),
                                 "otra.html: debe tener exactamente un <h1> "
                                 "(encontrados 2)")

    def test_empty_h1_fails(self) -> None:
        root, _ = self.two_pages(otra={"h1": "   "})
        self.assertSingleFailure(run_checker(root),
                                 "otra.html: el <h1> está vacío")

    def test_duplicate_h1_text_across_pages_fails(self) -> None:
        root, _ = self.two_pages(index={"h1": "Repetido"},
                                 otra={"h1": "Repetido"})
        self.assertSingleFailure(run_checker(root),
                                 "h1 duplicado 'repetido' en: "
                                 "['index.html', 'otra.html']")

    def test_skipped_heading_level_fails(self) -> None:
        root, _ = self.two_pages(
            otra={"body": "<h3>Sin h2 delante</h3>"})
        self.assertSingleFailure(run_checker(root),
                                 "salto de nivel en los encabezados: de h1 "
                                 "a h3")

    def test_contiguous_heading_levels_pass(self) -> None:
        root, _ = self.two_pages(
            otra={"body": "<h2>Seccion</h2><h3>Subseccion</h3>"})
        self.assertEqual(run_checker(root), [])

    # ── canonical ────────────────────────────────────────────────────

    def test_absolute_own_page_canonical_passes(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    def test_relative_canonical_fails(self) -> None:
        # Sin extension .html para que la regla de enlaces internos no
        # entre; el fallo debe ser solo el canonical no absoluto.
        root, _ = self.two_pages(
            index={"canonical": "/index"},
            sitemap=sitemap_for(["otra.html"]))
        self.assertSingleFailure(run_checker(root),
                                 "index.html: canonical no absoluto: "
                                 "'/index'")

    def test_canonical_of_another_page_fails(self) -> None:
        root, _ = self.two_pages(
            index={"canonical": canonical_url("otra.html")},
            # el sitemap generado a mano contiene la otra pagina y las
            # legales del helper, para que el fallo sea exclusivamente
            # el canonical
            sitemap=sitemap_for(["otra.html"]))
        self.assertSingleFailure(run_checker(root),
                                 "index.html: el canonical no apunta a esa "
                                 "misma pagina")

    # ── Open Graph ───────────────────────────────────────────────────

    def test_missing_og_tags_fail(self) -> None:
        for prop in ("og:title", "og:description", "og:type"):
            with self.subTest(prop=prop):
                tmp = tempfile.TemporaryDirectory()
                self.addCleanup(tmp.cleanup)
                html = page("otra.html").replace(
                    f'<meta property="{prop}" content=', '<meta data-x="')
                root = write_site(tmp.name, {
                    "index.html": page("index.html"), "otra.html": html})
                self.assertSingleFailure(run_checker(root),
                                         f'falta <meta property="{prop}">')

    def test_present_og_tags_pass(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    # ── sitemap.xml ──────────────────────────────────────────────────

    def test_sitemap_must_exist(self) -> None:
        root, _ = self.two_pages(sitemap=False)
        self.assertSingleFailure(run_checker(root), "falta sitemap.xml")

    def test_sitemap_missing_page_fails(self) -> None:
        root, _ = self.two_pages(sitemap=sitemap_for(["otra.html"]))
        self.assertSingleFailure(run_checker(root),
                                 "paginas ausentes en sitemap.xml: "
                                 f"['{canonical_url('index.html')}']")

    def test_sitemap_extra_entry_fails(self) -> None:
        root, _ = self.two_pages(sitemap=sitemap_for(
            ["index.html", "otra.html", "fantasma.html"]))
        self.assertSingleFailure(run_checker(root),
                                 "entradas de sitemap.xml sin pagina: "
                                 "['https://travelready.example/fantasma.html']")

    def test_sitemap_equal_to_canonical_set_passes(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    # ── robots.txt ───────────────────────────────────────────────────

    def test_robots_must_exist(self) -> None:
        root, _ = self.two_pages(robots=False)
        self.assertSingleFailure(run_checker(root), "falta robots.txt")

    def test_robots_wrong_sitemap_line_fails(self) -> None:
        root, _ = self.two_pages(
            robots="Sitemap: https://otro-origin.example/sitemap.xml\n")
        self.assertSingleFailure(run_checker(root),
                                 "robots.txt: la linea Sitemap no apunta al "
                                 "sitemap.xml del origen canonical")

    def test_robots_without_sitemap_line_fails(self) -> None:
        root, _ = self.two_pages(robots="User-agent: *\nAllow: /\n")
        self.assertSingleFailure(run_checker(root),
                                 "robots.txt sin linea Sitemap:")

    def test_robots_matching_sitemap_line_passes(self) -> None:
        root, _ = self.two_pages()
        self.assertEqual(run_checker(root), [])

    # ── prosa repetida ───────────────────────────────────────────────

    def test_repeated_long_prose_fails(self) -> None:
        body = f"<p>{LONG_PROSE}</p>"
        root, _ = self.two_pages(index={"body": body}, otra={"body": body})
        self.assertSingleFailure(run_checker(root),
                                 "prosa repetida entre paginas "
                                 "['index.html', 'otra.html']")

    def test_repeated_short_prose_passes(self) -> None:
        body = "<p>texto corto repetido, por debajo del umbral</p>"
        root, _ = self.two_pages(index={"body": body}, otra={"body": body})
        self.assertEqual(run_checker(root), [])

    def test_long_prose_on_one_page_only_passes(self) -> None:
        root, _ = self.two_pages(otra={"body": f"<p>{LONG_PROSE}</p>"})
        self.assertEqual(run_checker(root), [])

    # ── navegacion coherente con index.html ──────────────────────────

    def test_header_nav_mismatch_fails(self) -> None:
        # index no lleva nav; otra.html sí: la comparación contra la
        # referencia (index.html) se rompe.
        root, _ = self.two_pages(
            otra={"body": '<nav><ul><li><a href="index.html">Inicio</a></li>'
                          "</ul></nav>"})
        self.assertSingleFailure(run_checker(root),
                                 "navegacion de cabecera distinta en "
                                 "otra.html: esperado [], encontrado "
                                 "['index.html']")

    def test_header_nav_match_passes(self) -> None:
        nav = ('<nav><ul><li><a href="index.html">Inicio</a></li>'
               '<li><a href="otra.html">Otra</a></li></ul></nav>')
        root, _ = self.two_pages(index={"body": nav}, otra={"body": nav})
        self.assertEqual(run_checker(root), [])

    def test_footer_nav_mismatch_fails(self) -> None:
        # Ambas paginas llevan un nav de cabecera vacio e identico para
        # que la comparacion de cabecera calle: si no, el nav del pie de
        # otra.html seria navs[0] y romperia tambien la de cabecera.
        empty_header = "<nav><ul></ul></nav>"
        footer_ref = ('<nav class="footer"><ul>'
                      '<li><a href="index.html">Inicio</a></li></ul></nav>')
        footer_otra = ('<nav class="footer"><ul>'
                       '<li><a href="otra.html">Otra</a></li></ul></nav>')
        root, _ = self.two_pages(
            index={"body": empty_header + footer_ref},
            otra={"body": empty_header + footer_otra},
            css="body{margin:0}\n.footer{padding:1rem}\n")
        self.assertSingleFailure(run_checker(root),
                                 "navegacion de pie distinta en otra.html: "
                                 "esperado ['index.html'], encontrado "
                                 "['otra.html']")

    def test_footer_nav_match_passes(self) -> None:
        footer = ('<nav class="footer"><ul>'
                  '<li><a href="index.html">Inicio</a></li>'
                  '<li><a href="otra.html">Otra</a></li></ul></nav>')
        root, _ = self.two_pages(
            index={"body": "<nav><ul></ul></nav>" + footer},
            otra={"body": "<nav><ul></ul></nav>" + footer},
            css="body{margin:0}\n.footer{padding:1rem}\n")
        self.assertEqual(run_checker(root), [])


if __name__ == "__main__":
    unittest.main()
