"""Behaviour tests for __PROJECT_MODULE__.cli (lane: python).

Written to hold the `fail_under = 100` gate in pyproject.toml: one test per
rendered line of output, one per exit-code row, and one per branch inside
main() and resolve_word(). Coverage is a by-product of testing the contract,
not a target to game - if a line here is unreachable, the line in cli.py is
dead code and belongs in the delete column, not in an omit list.

Run: pytest tests/python      or:    tests/run.sh --lane python
"""

from __future__ import annotations

import sys

import pytest

from __PROJECT_MODULE__ import __version__
from __PROJECT_MODULE__.cli import (
    DEFAULT_GREETING_WORD,
    EXIT_OK,
    EXIT_USAGE,
    PROGRAM,
    build_greeting,
    greet,
    main,
    resolve_word,
    usage_text,
)


def test_version_is_a_semver_string() -> None:
    parts = __version__.split(".")
    assert len(parts) == 3
    assert all(part.isdigit() for part in parts)


def test_build_greeting_renders_word_name_and_bang() -> None:
    assert build_greeting("Hello", "Ada") == "Hello, Ada!"


def test_build_greeting_trims_both_arguments() -> None:
    assert build_greeting("  Howdy  ", "  Grace Hopper  ") == "Howdy, Grace Hopper!"


def test_build_greeting_falls_back_to_the_default_word() -> None:
    assert build_greeting("   ", "Ada") == f"{DEFAULT_GREETING_WORD}, Ada!"


def test_build_greeting_rejects_a_blank_name() -> None:
    with pytest.raises(ValueError, match="greet needs a name"):
        build_greeting("Hello", "   ")


def test_greet_reads_the_environment_word() -> None:
    assert greet("Ada") == f"{DEFAULT_GREETING_WORD}, Ada!"


def test_resolve_word_defaults_when_the_variable_is_unset(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("GREETING_WORD", raising=False)
    assert resolve_word() == DEFAULT_GREETING_WORD


def test_resolve_word_uses_the_configured_value(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GREETING_WORD", "Howdy")
    assert resolve_word() == "Howdy"


def test_resolve_word_treats_blank_as_unset(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GREETING_WORD", "   ")
    assert resolve_word() == DEFAULT_GREETING_WORD


def test_greet_honours_the_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GREETING_WORD", "Howdy")
    assert greet("Ada") == "Howdy, Ada!"


def test_usage_text_names_every_command() -> None:
    text = usage_text()
    assert "greet <name>" in text
    assert "--version" in text
    assert "GREETING_WORD" in text
    assert PROGRAM in text


def test_main_greet_prints_one_line_and_returns_zero(capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["greet", "Ada"]) == EXIT_OK
    captured = capsys.readouterr()
    assert captured.out == "Hello, Ada!\n"
    assert captured.err == ""


def test_main_greet_reads_the_environment(
    capsys: pytest.CaptureFixture[str], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("GREETING_WORD", "Howdy")
    assert main(["greet", "Ada"]) == EXIT_OK
    assert capsys.readouterr().out == "Howdy, Ada!\n"


def test_main_greet_without_a_name_is_a_usage_error(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["greet"]) == EXIT_USAGE
    captured = capsys.readouterr()
    assert captured.out == ""
    assert "greet needs exactly one name" in captured.err


def test_main_greet_with_a_blank_name_is_a_usage_error(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["greet", "   "]) == EXIT_USAGE
    captured = capsys.readouterr()
    assert captured.out == ""
    assert "greet needs a name" in captured.err


def test_main_version_prints_project_and_semver(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["--version"]) == EXIT_OK
    assert capsys.readouterr().out == f"{PROGRAM} {__version__}\n"


def test_main_version_alias_matches_the_flag(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["version"]) == EXIT_OK
    assert capsys.readouterr().out == f"{PROGRAM} {__version__}\n"


def test_main_help_succeeds_and_prints_usage(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["--help"]) == EXIT_OK
    captured = capsys.readouterr()
    assert captured.out.startswith(f"{PROGRAM} {__version__}")
    assert "Usage:" in captured.out
    assert captured.err == ""


def test_main_without_arguments_is_a_usage_error(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main([]) == EXIT_USAGE
    captured = capsys.readouterr()
    assert captured.out == ""
    assert captured.err.startswith("error: no command given")
    assert "Usage:" in captured.err


def test_main_unknown_command_names_the_offending_word(
    capsys: pytest.CaptureFixture[str],
) -> None:
    assert main(["frobnicate"]) == EXIT_USAGE
    captured = capsys.readouterr()
    assert captured.out == ""
    assert "unknown command: frobnicate" in captured.err


def test_main_defaults_to_sys_argv_when_argv_is_omitted(
    capsys: pytest.CaptureFixture[str], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(sys, "argv", ["__PROJECT_SLUG__", "greet", "Ada"])
    assert main() == EXIT_OK
    assert capsys.readouterr().out == "Hello, Ada!\n"
