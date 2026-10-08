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
encuentra alguna violacion. Sin argumento, fuera de un arbol de
trabajo de git o sin git instalado, informa con un ``aviso:`` y sale 0
sin dar veredicto alguno (igual que check_landing.py); con un
directorio explicito que no se pudo comprobar sale 1, porque una ruta
que el operador nombro es una pretension sobre que comprobar.
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


class Degradacion(Exception):
    """Git no puede comprobar nada: la puerta degrada a un aviso."""


class GitRoto(Exception):
    """Un comando de git fallo despues de que la sonda lo valido."""


def _raiz_de_trabajo(directory: Path) -> Path:
    """Raiz del arbol de trabajo que contiene ``directory``.

    ``git rev-parse --show-toplevel`` responde las dos preguntas de la
    puerta en una sola llamada: si git no esta instalado lanza OSError,
    si el directorio no vive dentro de un arbol de trabajo sale con
    error, y si devuelve una ruta es que git funciona. Solo los dos
    primeros casos degradan (``Degradacion``); a partir de una sonda
    exitosa, cualquier fallo de git es ``GitRoto``: nunca un aviso.
    """
    try:
        probe = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=directory, capture_output=True, check=True)
    except OSError as error:
        # Sin git instalado el propio subprocess.run avisa con
        # FileNotFoundError; cualquier otro OSError (permisos, ...) es
        # git rompiendose, no git ausente, y por eso no puede degradar.
        if isinstance(error, FileNotFoundError):
            raise Degradacion(
                "git no esta disponible en esta maquina") from None
        raise GitRoto(f"git no pudo ejecutarse: {error}") from None
    except subprocess.CalledProcessError:
        raise Degradacion(
            f"{directory} no es un arbol de trabajo de git") from None
    return Path(probe.stdout.decode("utf-8", "surrogateescape").strip())


def git_sets(directory: Path) -> tuple[set[str], set[str]]:
    """(rastreadas, ignoradas) bajo ``directory``, rutas relativas a la raiz.

    Una llamada pide el indice entero (``git ls-files``) y otra pregunta
    por las ignoradas (``git check-ignore --stdin`` con todas las
    candidatas de una vez). La sonda ``git rev-parse --show-toplevel``
    se ejecuta primero y separa las dos unicas degradaciones legitimas
    (git ausente, fuera de un arbol de trabajo), que lanzan
    ``Degradacion``. Todo el trabajo de git ocurre en
    la raiz resuelta y con rutas relativas a ella: invocar la puerta
    desde un subdirectorio comprueba exactamente lo mismo que la
    invocacion en la raiz. Cualquier otro fallo de git despues de una
    sonda exitosa lanza ``GitRoto``: un git degradado no puede colarse
    como aviso y producir una ejecucion verde que no verifico nada.
    """
    root = _raiz_de_trabajo(directory)
    try:
        listed = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=root, capture_output=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise GitRoto(f"git ls-files fallo en {root}: {error}") from None
    tracked = {name for name in listed.decode("utf-8", "surrogateescape")
               .split("\0") if name}

    candidates = REQUIRED_TRACKED + REQUIRED_IGNORED
    stdin = "\0".join(candidates) + "\0"
    try:
        answered = subprocess.run(
            ["git", "check-ignore", "-z", "--no-index", "--stdin"],
            cwd=root, capture_output=True, check=True,
            input=stdin.encode("utf-8", "surrogateescape")).stdout
    except OSError as error:
        raise GitRoto(
            f"git check-ignore fallo en {root}: {error}") from None
    except subprocess.CalledProcessError as error:
        if error.returncode != 1:
            raise GitRoto(
                f"git check-ignore fallo en {root}: {error}") from None
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
    cuando git no puede comprobar nada) y el resto son fallos, igual
    que en check_landing.py. El aviso solo afirma la causa que la
    sonda comprobo: git ausente o directorio fuera de un arbol de
    trabajo, nunca otra cosa. Un directorio que no existe tampoco
    degrada: no es "git ausente", es un directorio que no se puede
    comprobar.
    """
    if not directory.is_dir():
        return [f"no se pudo comprobar el directorio {directory}: "
                f"no existe"]
    try:
        sets = git_sets(directory)
    except Degradacion as degradacion:
        return [f"aviso: se omite la comprobacion de entradas rastreadas "
                f"e ignoradas por git: {degradacion}"]
    except GitRoto as roto:
        return [f"git se rompio durante la comprobacion: {roto}"]
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
    explicit = len(sys.argv) > 1
    directory = Path(sys.argv[1]) if explicit else Path(".")
    problems = check_directory(directory)

    for problem in problems:
        print(f"  - {problem}")

    # Un problema que dice que no se pudo comprobar no es una violacion
    # de las reglas: el veredicto lo distingue para no contar como
    # violacion lo que fue una puerta que no llego a mirar.
    no_comprobado = any(p.startswith(("aviso:", "no se pudo comprobar"))
                        for p in problems)

    # D3: un directorio que el operador nombra es una pretension sobre
    # que comprobar; si no se pudo comprobar, la salida es 1. El
    # degrade educado queda reservado para la invocacion sin argumento,
    # con parity con check_landing.py.
    if explicit and no_comprobado:
        # La causa ya quedo impresa en la linea de arriba: no se
        # repite aca, que es lo que este mismo arreglo le exige al
        # aviso de degradacion.
        print(f"\nFALLO: no se pudo comprobar el directorio {directory}.")
        return 1

    failures = [p for p in problems if not p.startswith("aviso:")]
    if failures:
        print(f"\nFALLO: {len(failures)} violacion(es) de entradas de git.")
        return 1

    # D2: si nada se comprobo, no hay veredicto OK que imprimir.
    if no_comprobado:
        print("\nAVISO: la comprobacion se omitio; nada quedo verificado.")
        return 0

    print("\nOK: entradas de construccion rastreadas y secretos ignorados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
