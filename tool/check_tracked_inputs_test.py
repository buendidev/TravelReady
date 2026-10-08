#!/usr/bin/env python3
"""Suite unittest de tool/check_tracked_inputs.py.

Cada test monta un repositorio git de verdad dentro de un directorio
temporal y llama al punto de entrada real del verificador
(``check_directory``): las reglas no estan reimplementadas aqui, se
comprueba el mensaje que sueltan. El caso feliz lleva todas las
entradas requeridas en su sitio; cada regla falla retirando lo que la
esconde. Solo biblioteca estandar y cero red: todo pasa con git local.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest import mock

import check_tracked_inputs

# .gitignore del caso feliz: los cuatro secretos quedan fuera del
# indice y nada de lo requerido como rastreado encaja en el.
GITIGNORE_VALIDO = """\
.env
android/key.properties
android/local.properties
android/app/*.keystore
"""


def git(root: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True,
                   capture_output=True)


def build_repo(root: Path, *, gitignore: str | None = GITIGNORE_VALIDO,
               on_disk: set[str] | None = None,
               tracked: set[str] | None = None) -> None:
    """Repositorio git de verdad dentro del directorio temporal.

    ``on_disk`` escribe esas rutas con contenido ficticio (por defecto,
    todas las requeridas, tanto rastreadas como secretos); ``tracked``
    las anade al indice una a una (por defecto, solo las requeridas
    como rastreadas); ``gitignore`` escribe el .gitignore antes de
    inicializar (``None`` lo omite).
    """
    if on_disk is None:
        on_disk = set(check_tracked_inputs.REQUIRED_TRACKED
                      + check_tracked_inputs.REQUIRED_IGNORED)
    if tracked is None:
        tracked = set(check_tracked_inputs.REQUIRED_TRACKED)
    for name in on_disk:
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"{name}\n", encoding="utf-8")
    if gitignore is not None:
        (root / ".gitignore").write_text(gitignore, encoding="utf-8")
    git(root, "init", "-q")
    for name in sorted(tracked):
        # -f: un fixture que prueba "rastreado pero ignorado" necesita
        # colarse en el indice a pesar de la regla del .gitignore.
        git(root, "add", "-f", name)


def run_checker(root: Path) -> list[str]:
    return check_tracked_inputs.check_directory(root)


def failures(problems: list[str]) -> list[str]:
    """Los problemas que hacen salir 1: los avisos no cuentan."""
    return [p for p in problems if not p.startswith("aviso:")]


class CheckerTestCase(unittest.TestCase):
    """Base con directorio temporal y aserto de fallo unico."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)

    def assertSingleFailure(self, problems: list[str], expected: str) -> None:
        """Falla, y por lo que se pide, citando el mensaje."""
        self.maxDiff = None
        joined = "\n".join(problems)
        self.assertIn(expected, joined)
        self.assertEqual(len(failures(problems)), 1,
                         f"fallos inesperados: {failures(problems)}")


class EntradasRastreadasTest(CheckerTestCase):
    """Regla REQUIRED_TRACKED: rastreadas por git y nunca ignoradas."""

    def test_all_required_tracked_and_not_ignored_passes(self) -> None:
        root = self.root
        build_repo(root)
        self.assertEqual(run_checker(root), [])

    def test_missing_required_input_fails(self) -> None:
        # Ni en disco ni en el indice: la ausencia silenciosa que esta
        # puerta vigila (el caso firebase_options.dart).
        root = self.root
        build_repo(root,
                   on_disk=(set(check_tracked_inputs.REQUIRED_TRACKED)
                            | set(check_tracked_inputs.REQUIRED_IGNORED))
                   - {"lib/firebase_options.dart"},
                   tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   - {"lib/firebase_options.dart"})
        # W4: el fixture debe decir la verdad: la entrada ausente no
        # puede seguir en disco, o el test duplica el caso de arriba.
        self.assertFalse(
            (root / "lib/firebase_options.dart").exists(),
            "el fixture no quito la entrada: precedencia de | y -")
        self.assertSingleFailure(
            run_checker(root),
            "lib/firebase_options.dart: no esta rastreado por git")

    def test_present_but_untracked_input_fails(self) -> None:
        # En disco pero fuera del indice: git lo saltaria igual que si
        # no existiera.
        root = self.root
        build_repo(root,
                   tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   - {"android/gradlew"})
        self.assertSingleFailure(
            run_checker(root),
            "android/gradlew: no esta rastreado por git")

    def test_tracked_but_ignored_input_fails(self) -> None:
        # Rastreado a la fuerza hoy, pero el .gitignore lo cubre: el
        # proximo limpiado del indice lo haria desaparecer.
        root = self.root
        build_repo(root, gitignore=GITIGNORE_VALIDO + "*.jar\n")
        self.assertSingleFailure(
            run_checker(root),
            "android/gradle/wrapper/gradle-wrapper.jar: el .gitignore "
            "lo ignora")


class SecretosIgnoradosTest(CheckerTestCase):
    """Regla REQUIRED_IGNORED: ignorados y jamas rastreados."""

    def test_all_required_ignored_and_untracked_passes(self) -> None:
        root = self.root
        build_repo(root)
        self.assertEqual(run_checker(root), [])

    def test_secret_not_ignored_fails(self) -> None:
        # Sin regla para el .env, queda a un git add de publicarse;
        # los otros tres secretos conservan su cobertura.
        root = self.root
        build_repo(root,
                   gitignore="android/key.properties\n"
                             "android/local.properties\n"
                             "android/app/*.keystore\n")
        self.assertSingleFailure(
            run_checker(root),
            ".env: no esta ignorado por el .gitignore")

    def test_secret_tracked_fails(self) -> None:
        # El secreto ya esta en el indice aunque el .gitignore lo
        # liste: el espejo exacto del defecto de los build inputs.
        root = self.root
        build_repo(root, tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   | {".env"})
        self.assertSingleFailure(
            run_checker(root),
            ".env: es un secreto y esta rastreado por git")


class GitRotoTest(CheckerTestCase):
    """Tras una sonda exitosa, un fallo de git es violacion, no aviso."""

    def test_corrupt_index_is_a_hard_failure_not_a_skip(self) -> None:
        # Reproduccion real del defecto fail-open, sin mocks: un indice
        # corrupto no impide que la sonda responda, pero si que
        # git ls-files lea el indice. Hoy eso sale como aviso y 0.
        root = self.root
        build_repo(root)
        (root / ".git" / "index").write_bytes(b"not an index")
        problems = run_checker(root)
        self.assertEqual(len(failures(problems)), 1, problems)
        self.assertFalse(any(p.startswith("aviso:") for p in problems),
                         problems)

    def test_ls_files_failure_after_probe_is_hard_failure(self) -> None:
        # Un git ls-files que falla sin ser "fuera del arbol" no puede
        # colarse como aviso: un git degradado en CI saldria verde.
        root = self.root
        build_repo(root)
        real_run = check_tracked_inputs.subprocess.run

        def roto(args, **kwargs):
            if "ls-files" in args:
                raise subprocess.CalledProcessError(128, args)
            return real_run(args, **kwargs)

        with mock.patch.object(check_tracked_inputs.subprocess, "run",
                               side_effect=roto):
            problems = run_checker(root)
        self.assertEqual(len(failures(problems)), 1, problems)

    def test_check_ignore_oserror_is_hard_failure(self) -> None:
        # check-ignore solo capturaba CalledProcessError: un OSError
        # (disco lleno, permisos, ...) reventaba la puerta entera.
        root = self.root
        build_repo(root)
        real_run = check_tracked_inputs.subprocess.run

        def roto(args, **kwargs):
            if "check-ignore" in args:
                raise OSError("sin espacio en disco")
            return real_run(args, **kwargs)

        with mock.patch.object(check_tracked_inputs.subprocess, "run",
                               side_effect=roto):
            problems = run_checker(root)
        self.assertEqual(len(failures(problems)), 1, problems)


class InvocadoDesdeSubdirectorioTest(CheckerTestCase):
    """Invocada con un subdirectorio, comprueba lo mismo que en la raiz."""

    def test_subdirectory_checks_the_same_as_the_root(self) -> None:
        # git ls-files -- . respondia en rutas relativas al
        # subdirectorio: toda entrada requerida parecia sin rastrear.
        root = self.root
        build_repo(root)
        website = root / "website"
        website.mkdir()
        self.assertEqual(run_checker(website), [])


class FueraDeArbolGitTest(CheckerTestCase):
    """Sin git utilizable la puerta degrada a aviso y no molesta."""

    def test_not_a_git_repo_emits_single_aviso(self) -> None:
        root = self.root
        # Archivos en disco pero sin git init: no hay arbol de trabajo.
        for name in check_tracked_inputs.REQUIRED_TRACKED:
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"{name}\n", encoding="utf-8")
        (root / ".gitignore").write_text(GITIGNORE_VALIDO,
                                         encoding="utf-8")
        problems = run_checker(root)
        self.assertEqual(len(problems), 1, problems)
        self.assertTrue(problems[0].startswith("aviso:"), problems)
        # R2-004: el aviso solo afirma la causa que se comprobo.
        self.assertIn("no es un arbol de trabajo de git", problems[0])

    def test_git_absent_emits_aviso(self) -> None:
        root = self.root
        build_repo(root)
        with mock.patch.object(check_tracked_inputs.subprocess, "run",
                               side_effect=FileNotFoundError("git")):
            problems = run_checker(root)
        self.assertEqual(len(problems), 1, problems)
        self.assertTrue(problems[0].startswith("aviso:"), problems)
        # R2-004: git ausente no es "no es un arbol de trabajo".
        self.assertIn("git no esta disponible", problems[0])


class CommandLineTest(CheckerTestCase):
    """El CLI: un mensaje por violacion, OK, y codigos de salida."""

    def run_main(self, root: Path | None = None) -> tuple[int, str]:
        argv = ["check_tracked_inputs.py"]
        if root is not None:
            argv.append(str(root))
        out = StringIO()
        with mock.patch.object(sys, "argv", argv):
            with redirect_stdout(out):
                code = check_tracked_inputs.main()
        return code, out.getvalue()

    def test_ok_repo_exits_zero_and_prints_ok(self) -> None:
        root = self.root
        build_repo(root)
        code, output = self.run_main(root)
        self.assertEqual(code, 0)
        self.assertIn("OK:", output)

    def test_broken_repo_exits_one_with_one_message_per_violation(
            self) -> None:
        root = self.root
        build_repo(root,
                   # El .gitignore cubre los otros tres secretos para
                   # que el recuento cierre en las tres violaciones
                   # que el comentario promete.
                   gitignore="android/key.properties\n"
                             "android/local.properties\n"
                             "android/app/*.keystore\n",
                   tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   - {"android/gradlew.bat"} | {".env"})
        code, output = self.run_main(root)
        self.assertEqual(code, 1)
        # Tres violaciones, tres mensajes: gradlew.bat sin rastrear,
        # .env ni ignorado ni rastreado: dos violaciones del mismo
        # secreto, una por condicion rota.
        self.assertIn("android/gradlew.bat: no esta rastreado por git",
                      output)
        self.assertIn(".env: no esta ignorado por el .gitignore", output)
        self.assertIn(".env: es un secreto y esta rastreado por git",
                      output)
        self.assertIn("FALLO:", output)
        self.assertNotIn("OK:", output)
        # W4: nada suelto, el recuento de violaciones queda fijado.
        violation_lines = [line for line in output.splitlines()
                           if line.startswith("  - ")
                           and not line.lstrip().startswith("aviso:")]
        self.assertEqual(len(violation_lines), 3, violation_lines)
        self.assertIn("FALLO: 3 violacion(es)", output)

    def test_main_with_subdirectory_of_repo_exits_zero(self) -> None:
        # cd website && python ../tool/check_tracked_inputs.py: la
        # puerta debe comportarse igual que invocada en la raiz.
        root = self.root
        build_repo(root)
        website = root / "website"
        website.mkdir()
        code, output = self.run_main(website)
        self.assertEqual(code, 0)
        self.assertIn("OK:", output)

    def test_corrupt_index_exits_one(self) -> None:
        # El mismo defecto fail-open, visto desde el CLI: un git
        # degradado no puede salir verde.
        root = self.root
        build_repo(root)
        (root / ".git" / "index").write_bytes(b"not an index")
        code, output = self.run_main(root)
        self.assertEqual(code, 1)
        self.assertIn("FALLO:", output)
        self.assertNotIn("OK:", output)
        self.assertNotIn("aviso:", output)

    def test_default_directory_degrades_to_aviso_without_ok(
            self) -> None:
        # (a) Sin argumento y sin arbol de trabajo: aviso unico, salida
        # 0, y ningun veredicto OK que la puerta no se gano (D2).
        anterior = Path.cwd()
        os.chdir(self.root)
        self.addCleanup(os.chdir, anterior)
        code, output = self.run_main()
        self.assertEqual(code, 0)
        avisos = [line for line in output.splitlines()
                  if "aviso:" in line]
        self.assertEqual(len(avisos), 1, output)
        self.assertNotIn("OK:", output)

    def test_explicit_directory_that_is_not_a_work_tree_exits_one(
            self) -> None:
        # (b) D3: el directorio que el operador nombra es una pretension
        # sobre que comprobar; un typo no puede salir verde.
        root = self.root
        code, output = self.run_main(root)
        self.assertEqual(code, 1)
        self.assertIn("no se pudo comprobar el directorio", output)

    def test_explicit_missing_directory_exits_one(self) -> None:
        # D3: un directorio que no existe es el mismo caso; un
        # FileNotFoundError de un cwd mala no es "git ausente".
        code, output = self.run_main(self.root / "no_existe")
        self.assertEqual(code, 1)
        self.assertIn("no se pudo comprobar el directorio", output)
        # Un directorio que no se pudo comprobar no es una violacion de
        # las reglas: el veredicto no puede contarlo como tal.
        self.assertNotIn("violacion(es)", output)
        self.assertNotIn("OK:", output)


if __name__ == "__main__":
    unittest.main()
