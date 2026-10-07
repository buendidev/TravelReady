#!/usr/bin/env python3
"""Entradas de construccion y secretos: lo que git debe y no debe seguir.

La clase de defecto que esta puerta vigila tiene dos caras. La primera:
un .gitignore demasiado amplio esconde en silencio una entrada necesaria
para compilar (firebase_options.dart, el wrapper de Gradle, ...), todas
las maquinas con el repo ya clonado pasan y un clon limpio falla en CI
sin que nadie sepa por que. La segunda es el espejo: un secreto (.env,
el keystore, ...) que un git add descuidado sube al repositorio.

Las reglas viven aqui arriba como datos: cada entrada de
``REQUIRED_TRACKED`` debe salir en ``git ls-files`` y no encajar en
ninguna regla de ignorados; cada entrada de ``REQUIRED_IGNORED`` debe
encajar en el .gitignore y no estar rastreada. Git se pregunta una sola
vez por ejecucion por el conjunto rastreado y otra por el conjunto de
ignorados: nunca un proceso de git por ruta.

Uso:
    python tool/check_tracked_inputs.py [directorio]   # por defecto: .
Sale con codigo 0 si solo queda el aviso de degradacion y 1 si
encuentra alguna violacion; fuera de un arbol de trabajo de git
informa con un ``aviso:`` y sale 0, igual que check_landing.py.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# Entradas de construccion: deben estar rastreadas por git y no ser
# ignoradas. Sin una de estas un clon limpio no compila ni despliega.
REQUIRED_TRACKED = (
    "lib/firebase_options.dart",
    "android/app/google-services.json",
    "android/gradlew",
    "android/gradlew.bat",
    "android/gradle/wrapper/gradle-wrapper.jar",
    "firebase.json",
    "firestore.rules",
    "firestore.indexes.json",
    "storage.rules",
)

# Secretos: deben estar ignorados por el .gitignore y jamas rastreados.
REQUIRED_IGNORED = (
    ".env",
    "android/key.properties",
    "android/local.properties",
    "android/app/travelready-release.keystore",
)


def git_sets(directory: Path) -> tuple[set[str], set[str]] | None:
    """(rastreadas, ignoradas) bajo ``directory``, en rutas relativas.

    Una llamada pide el indice entero (``git ls-files``) y otra pregunta
    por las ignoradas (``git check-ignore --stdin`` con todas las
    candidatas de una vez). Si git no esta disponible o el directorio no
    vive en un arbol de trabajo se devuelve None, y la llamada a la
    puerta degrada a un aviso: la ausencia de git no es una violacion.
    """
    try:
        listed = subprocess.run(
            ["git", "ls-files", "-z", "--", "."],
            cwd=directory, capture_output=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return None
    tracked = {name for name in listed.decode("utf-8", "surrogateescape")
               .split("\0") if name}

    candidates = REQUIRED_TRACKED + REQUIRED_IGNORED
    stdin = "\0".join(candidates) + "\0"
    try:
        answered = subprocess.run(
            ["git", "check-ignore", "-z", "--no-index", "--stdin"],
            cwd=directory, capture_output=True, check=True,
            input=stdin.encode("utf-8", "surrogateescape")).stdout
    except subprocess.CalledProcessError:
        # Sin ninguna coincidencia check-ignore sale 1: no hay
        # ignoradas que reportar, no es un error de git.
        answered = b""
    ignored = {name for name in
               answered.decode("utf-8", "surrogateescape").split("\0")
               if name}
    return tracked, ignored


def check_directory(directory: Path) -> list[str]:
    """Comprueba las reglas y devuelve un mensaje por violacion.

    Los mensajes con prefijo ``aviso:`` son informativos (degradacion
    fuera de git) y el resto son fallos, igual que en check_landing.py.
    """
    sets = git_sets(directory)
    if sets is None:
        return [f"aviso: se omite la comprobacion de entradas rastreadas "
                f"e ignoradas por git: {directory} no es un arbol de "
                f"trabajo de git"]
    tracked, ignored = sets
    problems: list[str] = []

    for name in REQUIRED_TRACKED:
        if name not in tracked:
            problems.append(
                f"{name}: no esta rastreado por git: un clon limpio no "
                f"puede construir sin el")
        if name in ignored:
            problems.append(
                f"{name}: el .gitignore lo ignora: acabaria desapareciendo "
                f"del repositorio")

    for name in REQUIRED_IGNORED:
        if name not in ignored:
            problems.append(
                f"{name}: no esta ignorado por el .gitignore: un git add "
                f"podria publicar el secreto")
        if name in tracked:
            problems.append(
                f"{name}: es un secreto y esta rastreado por git: sacalo "
                f"del indice")
    return problems


def main() -> int:
    directory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    problems = check_directory(directory)

    for problem in problems:
        print(f"  - {problem}")

    failures = [p for p in problems if not p.startswith("aviso:")]
    if failures:
        print(f"\nFALLO: {len(failures)} violacion(es) de entradas de git.")
        return 1
    print("\nOK: entradas de construccion rastreadas y secretos ignorados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
