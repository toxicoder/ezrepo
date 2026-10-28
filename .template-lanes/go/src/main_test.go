package main

import (
	"bytes"
	"strings"
	"testing"
)

// envWith returns the environment lookup a test wants: only GREETING_WORD is
// answered, everything else is unset. Injecting it is why resolveWord never
// touches os, and why no test here has to mutate process state.
func envWith(word string) func(string) string {
	return func(key string) string {
		if key == envGreetingWord {
			return word
		}

		return ""
	}
}

// envUnset is the lookup for "GREETING_WORD is not in the environment at all".
func envUnset(string) string { return "" }

// execRun drives run() with captured writers and hands back both streams.
func execRun(argv []string, getenv func(string) string) (code int, stdout, stderr string) {
	var out, errw bytes.Buffer

	code = run(argv, &out, &errw, getenv)

	return code, out.String(), errw.String()
}

// TestRunGreetings is the stdout contract for the one real command: exact bytes,
// nothing on stderr, exit 0.
func TestRunGreetings(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		argv []string
		word string
		want string
	}{
		{name: "default word", argv: []string{"greet", "Ada"}, want: "Hello, Ada!\n"},
		{name: "GREETING_WORD wins", argv: []string{"greet", "Ada"}, word: "Howdy", want: "Howdy, Ada!\n"},
		{name: "blank GREETING_WORD falls back", argv: []string{"greet", "Ada"}, word: "   ", want: "Hello, Ada!\n"},
		{name: "multiword name", argv: []string{"greet", "Ada Lovelace"}, want: "Hello, Ada Lovelace!\n"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			code, stdout, stderr := execRun(tc.argv, envWith(tc.word))
			if code != exitOK {
				t.Errorf("run(%v) exit = %d, want %d", tc.argv, code, exitOK)
			}
			if stdout != tc.want {
				t.Errorf("run(%v) stdout = %q, want %q", tc.argv, stdout, tc.want)
			}
			if stderr != "" {
				t.Errorf("run(%v) wrote to stderr on a success path: %q", tc.argv, stderr)
			}
		})
	}
}

// TestRunVersion pins --version: one line, "<project> <version>", from the two
// constants and nowhere else.
func TestRunVersion(t *testing.T) {
	t.Parallel()

	want := projectName + " " + version + "\n"

	for _, argv := range [][]string{{"--version"}, {"version"}} {
		t.Run(argv[0], func(t *testing.T) {
			t.Parallel()

			code, stdout, stderr := execRun(argv, envUnset)
			if code != exitOK {
				t.Errorf("run(%v) exit = %d, want %d", argv, code, exitOK)
			}
			if stdout != want {
				t.Errorf("run(%v) stdout = %q, want %q", argv, stdout, want)
			}
			if stderr != "" {
				t.Errorf("run(%v) wrote to stderr on a success path: %q", argv, stderr)
			}
		})
	}
}

// TestRunHelpGoesToStdout asserts help is a result, not a diagnostic: exit 0,
// the usage block on stdout, nothing on stderr.
func TestRunHelpGoesToStdout(t *testing.T) {
	t.Parallel()

	for _, argv := range [][]string{{"-h"}, {"--help"}, {"help"}} {
		t.Run(argv[0], func(t *testing.T) {
			t.Parallel()

			code, stdout, stderr := execRun(argv, envUnset)
			if code != exitOK {
				t.Errorf("run(%v) exit = %d, want %d", argv, code, exitOK)
			}
			if !strings.Contains(stdout, "Usage:\n") {
				t.Errorf("run(%v) stdout carries no usage block: %q", argv, stdout)
			}
			for _, want := range []string{envGreetingWord, "greet <name>", "--version", "2  bad arguments"} {
				if !strings.Contains(stdout, want) {
					t.Errorf("run(%v) usage text is missing %q:\n%s", argv, want, stdout)
				}
			}
			if stderr != "" {
				t.Errorf("run(%v) wrote to stderr on --help: %q", argv, stderr)
			}
		})
	}
}

// TestRunUsageErrors is the exit-code table. Every row also asserts the stdout
// half of the house rule: a failing run leaves stdout empty, so a redirected
// result file is never polluted by a diagnostic.
func TestRunUsageErrors(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		argv    []string
		wantErr string
	}{
		{name: "no command", argv: nil, wantErr: "error: no command given\n"},
		{name: "unknown command", argv: []string{"fly"}, wantErr: "error: unknown command: fly\n"},
		{
			name:    "greet without a name",
			argv:    []string{"greet"},
			wantErr: "error: greet needs a name, for example: " + projectName + " greet Ada\n",
		},
		{
			name:    "greet with a blank name",
			argv:    []string{"greet", "   "},
			wantErr: "error: greet needs a name, for example: " + projectName + " greet Ada\n",
		},
		{
			name:    "greet with two names",
			argv:    []string{"greet", "Ada", "Lovelace"},
			wantErr: "error: greet needs a name, for example: " + projectName + " greet Ada\n",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			code, stdout, stderr := execRun(tc.argv, envUnset)
			if code != exitUsage {
				t.Errorf("run(%v) exit = %d, want %d", tc.argv, code, exitUsage)
			}
			if !strings.HasPrefix(stderr, tc.wantErr) {
				t.Errorf("run(%v) stderr = %q, want it to start with %q", tc.argv, stderr, tc.wantErr)
			}
			if stdout != "" {
				t.Errorf("run(%v) wrote to stdout on an error path: %q", tc.argv, stdout)
			}
		})
	}
}

// TestResolveWord covers the environment contract directly, including the unset
// case that envWith cannot express (a blank value and an absent value are
// different lookups).
func TestResolveWord(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		getenv func(string) string
		want   string
	}{
		{name: "unset", getenv: envUnset, want: "Hello"},
		{name: "empty", getenv: envWith(""), want: "Hello"},
		{name: "whitespace", getenv: envWith(" \t "), want: "Hello"},
		{name: "set", getenv: envWith("Howdy"), want: "Howdy"},
		{name: "kept verbatim", getenv: envWith("  Hi  "), want: "  Hi  "},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			if got := resolveWord(tc.getenv); got != tc.want {
				t.Errorf("resolveWord() = %q, want %q", got, tc.want)
			}
		})
	}
}
