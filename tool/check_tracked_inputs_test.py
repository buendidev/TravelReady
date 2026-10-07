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
                   on_disk=set(check_tracked_inputs.REQUIRED_TRACKED)
                   | set(check_tracked_inputs.REQUIRED_IGNORED)
                   - {"lib/firebase_options.dart"},
                   tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   - {"lib/firebase_options.dart"})
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

    def test_git_absent_emits_aviso(self) -> None:
        root = self.root
        build_repo(root)
        with mock.patch.object(check_tracked_inputs.subprocess, "run",
                               side_effect=FileNotFoundError("git")):
            problems = run_checker(root)
        self.assertEqual(len(problems), 1, problems)
        self.assertTrue(problems[0].startswith("aviso:"), problems)


class CommandLineTest(CheckerTestCase):
    """El CLI: un mensaje por violacion, OK, y codigos de salida."""

    def run_main(self, root: Path) -> tuple[int, str]:
        out = StringIO()
        with mock.patch.object(sys, "argv",
                               ["check_tracked_inputs.py", str(root)]):
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
        build_repo(root, gitignore="",
                   tracked=set(check_tracked_inputs.REQUIRED_TRACKED)
                   - {"android/gradlew.bat"} | {".env"})
        code, output = self.run_main(root)
        self.assertEqual(code, 1)
        # Tres violaciones, tres mensajes: gradlew.bat sin rastrear,
        # .env ni ignorado ni... rastreado: dos violaciones del mismo
        # secreto, una por condicion rota.
        self.assertIn("android/gradlew.bat: no esta rastreado por git",
                      output)
        self.assertIn(".env: no esta ignorado por el .gitignore", output)
        self.assertIn(".env: es un secreto y esta rastreado por git",
                      output)
        self.assertIn("FALLO:", output)
        self.assertNotIn("OK:", output)

    def test_aviso_repo_exits_zero_without_ok_verdict(self) -> None:
        # Sin arbol de trabajo: el aviso se imprime y se sale 0.
        root = self.root
        code, output = self.run_main(root)
        self.assertEqual(code, 0)
        self.assertIn("aviso: se omite la comprobacion", output)


if __name__ == "__main__":
    unittest.main()
