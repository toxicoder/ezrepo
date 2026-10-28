"""The command line face of __PROJECT_NAME__.

Three commands and one environment variable, mirroring the shell lane exactly:

* ``greet <name>``  print one greeting line
* ``--version``     print ``<project> <semver>``
* ``--help``        print the usage block
* ``GREETING_WORD`` the word ``greet`` uses; unset, empty or blank means
  :data:`DEFAULT_GREETING_WORD`

Two rules make this module importable from a test without a subprocess. First,
every function returns an exit code instead of calling ``sys.exit``, so nothing
here can end the interpreter. Second, output goes through :func:`print` to the
live ``sys.stdout`` / ``sys.stderr``, which a test captures with ``capsys``.

Exit codes, asserted in ``tests/python/test_cli.py``:

* ``0`` the command ran
* ``2`` argv was wrong: no command, unknown command, or ``greet`` without a name
"""

from __future__ import annotations

import os
import sys

from __PROJECT_MODULE__ import __version__

PROGRAM = "__PROJECT_NAME__"
DEFAULT_GREETING_WORD = "Hello"

EXIT_OK = 0
EXIT_USAGE = 2

GREETING_WORD_ENV = "GREETING_WORD"


def resolve_word() -> str:
    """Return the greeting word this invocation should use.

    The environment variable is optional. Unset, empty and all-whitespace all
    mean "use the default", because a blank ``GREETING_WORD`` leaking in from a
    container environment should print ``Hello, Ada!`` and not ``, Ada!``.

    Returns:
        The configured word with surrounding whitespace removed, or
        :data:`DEFAULT_GREETING_WORD` when nothing usable is configured.
    """
    word = os.environ.get(GREETING_WORD_ENV, DEFAULT_GREETING_WORD).strip()
    if not word:
        return DEFAULT_GREETING_WORD
    return word


def greet(name: str) -> str:
    """Compose the greeting line for ``name``.

    This is the only function that decides what a greeting looks like. It is
    pure: same arguments, same string, no I/O, no environment read. The caller
    chooses the word, so a caller that wants a fixed greeting can bypass the
    environment entirely by passing it to :func:`build_greeting`.

    Args:
        name: The name to greet. Surrounding whitespace is ignored.

    Returns:
        One line, ``<word>, <name>!``, without a trailing newline.

    Raises:
        ValueError: If ``name`` is empty or whitespace only.
    """
    return build_greeting(resolve_word(), name)


def build_greeting(word: str, name: str) -> str:
    """Render ``<word>, <name>!`` from two strings.

    The pure half of the rendering, kept separate from :func:`greet` so a test
    can pin the format without touching the environment.

    Args:
        word: The greeting word; blank falls back to
            :data:`DEFAULT_GREETING_WORD`.
        name: The name to greet; surrounding whitespace is stripped.

    Returns:
        The greeting line, without a trailing newline.

    Raises:
        ValueError: If ``name`` is empty or whitespace only.
    """
    trimmed_name = name.strip()
    if not trimmed_name:
        raise ValueError("greet needs a name, for example: greet Ada")
    trimmed_word = word.strip() or DEFAULT_GREETING_WORD
    return f"{trimmed_word}, {trimmed_name}!"


def usage_text() -> str:
    """Return the help block.

    A function rather than a module constant so the text can read the live
    :data:`PROGRAM` name, which the render step substitutes.

    Returns:
        The multi-line usage text, terminated by a newline.
    """
    return (
        f"{PROGRAM} {__version__} - __PROJECT_DESCRIPTION__\n"
        "\n"
        "Usage:\n"
        f"  {PROGRAM} greet <name>\n"
        f"  {PROGRAM} --version\n"
        f"  {PROGRAM} --help\n"
        "\n"
        "Environment:\n"
        f"  {GREETING_WORD_ENV}   word used by \"greet\" (default: {DEFAULT_GREETING_WORD})\n"
        "\n"
        "Exit codes:\n"
        "  0  success\n"
        "  2  bad arguments\n"
    )


def main(argv: list[str] | None = None) -> int:
    """Run the CLI and return its exit code.

    Never calls :func:`sys.exit`, so a test can drive it in-process and a
    console-script wrapper can use it as the entry point named in
    ``pyproject.toml``.

    Args:
        argv: The arguments after the program name. ``None`` means "read
            ``sys.argv[1:]``", which is what the installed wrapper does.

    Returns:
        :data:`EXIT_OK` when a command ran, :data:`EXIT_USAGE` for any argv
        mistake. Diagnostics go to stderr, results to stdout.
    """
    args = list(sys.argv[1:]) if argv is None else list(argv)

    if not args:
        sys.stderr.write(f"error: no command given\n{usage_text()}")
        return EXIT_USAGE

    command = args[0]

    if command in ("--version", "version"):
        print(f"{PROGRAM} {__version__}")
        return EXIT_OK

    if command in ("-h", "--help", "help"):
        print(usage_text(), end="")
        return EXIT_OK

    if command == "greet":
        if len(args) != 2:
            sys.stderr.write(
                f"error: greet needs exactly one name, for example: {PROGRAM} greet Ada\n"
            )
            return EXIT_USAGE
        try:
            line = greet(args[1])
        except ValueError as exc:
            sys.stderr.write(f"error: {exc}\n")
            return EXIT_USAGE
        print(line)
        return EXIT_OK

    sys.stderr.write(f"error: unknown command: {command}\n{usage_text()}")
    return EXIT_USAGE


if __name__ == "__main__":
    raise SystemExit(main())
