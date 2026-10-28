// Package main is the __PROJECT_NAME__ command line entry point.
//
// __PROJECT_DESCRIPTION__: that is the whole job. The CLI is two commands and one
// environment variable, and that is the point: this file is the reference shape
// every other Go file in the repo copies. It is the Go spelling of the shell
// lane's src/main.sh and the python lane's cli.py.
//   - `greet <name>` prints one greeting line.
//   - `--version` prints "<project> <semver>" so a packager and a smoke test can
//     both parse it.
//   - `GREETING_WORD` changes the word; unset or blank means "Hello".
//
// Go's real entry point takes no arguments and returns nothing, so the testable
// entry point is run(): it takes argv, both writers and the environment lookup,
// and returns the exit code. main() is the one line that wires os.Args,
// os.Stdout, os.Stderr and os.Getenv into it. Every branch above main is
// reachable from src/main_test.go without spawning a subprocess.
//
// Exit codes, asserted by src/main_test.go:
//
//	0  the command ran
//	2  argv was wrong: no command, unknown command, or greet without a name
//
// Anything fatal goes to stderr and nothing fatal goes to stdout, so
// `__PROJECT_NAME__ greet Ada > out.txt` never writes a diagnostic into the
// file. The rendering itself lives in internal/greet, not here: this file parses
// argv, chooses an exit code, and prints.
package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/__PROJECT_OWNER__/__PROJECT_SLUG__/internal/greet"
)

// version is the single version string of the project. No other line in the
// repo hard-codes a number: --version prints this constant, the release tag is
// cut from it, and the test for --version asserts against it.
const version = "0.1.0"

// projectName is the rendered project name, used in --version and the usage
// text. The scaffolding CLI substitutes it, so nothing here greps argv for the
// program name (which os.Args[0] may not even carry).
const projectName = "__PROJECT_NAME__"

// envGreetingWord names the environment variable that overrides the word.
const envGreetingWord = "GREETING_WORD"

// Exit codes. Named, because "return 2" in three places tells a reader nothing.
const (
	exitOK    = 0
	exitUsage = 2
)

// usage writes the command list and the environment contract to w.
//
// It takes the writer instead of printing, because the error paths send usage to
// stderr while --help sends it to stdout, and a test asserts which is which.
func usage(w io.Writer) {
	_, _ = fmt.Fprintf(w, `%s %s - __PROJECT_DESCRIPTION__

Usage:
  %s greet <name>
  %s --version
  %s --help

Environment:
  %s   word used by "greet" (default: %s)

Exit codes:
  0  success
  2  bad arguments
`, projectName, version, projectName, projectName, projectName, envGreetingWord, greet.DefaultWord)
}

// resolveWord returns the greeting word this invocation should use.
//
// The variable is optional: unset, empty, or all-whitespace all mean "use the
// documented default", because an accidentally blank GREETING_WORD in a
// container environment should print "Hello, Ada!" and not ", Ada!". The lookup
// is injected rather than read from os directly so the test can hand this
// function a value without mutating the process environment.
func resolveWord(getenv func(string) string) string {
	word := getenv(envGreetingWord)
	if strings.TrimSpace(word) == "" {
		return greet.DefaultWord
	}

	return word
}

// cmdGreet handles `greet <name>` and returns the process exit code.
func cmdGreet(args []string, stdout, stderr io.Writer, getenv func(string) string) int {
	if len(args) != 1 || strings.TrimSpace(args[0]) == "" {
		_, _ = fmt.Fprintf(stderr, "error: greet needs a name, for example: %s greet Ada\n", projectName)
		return exitUsage
	}

	_, _ = fmt.Fprintln(stdout, greet.Greeting(resolveWord(getenv), args[0]))

	return exitOK
}

// run is the entry point: it dispatches one argv vector to a subcommand and
// returns the code the process should exit with. It never calls os.Exit and
// never touches an os global, which is what lets the whole table in
// src/main_test.go run in one process.
func run(argv []string, stdout, stderr io.Writer, getenv func(string) string) int {
	if len(argv) == 0 {
		_, _ = fmt.Fprintln(stderr, "error: no command given")
		usage(stderr)
		return exitUsage
	}

	switch argv[0] {
	case "greet":
		return cmdGreet(argv[1:], stdout, stderr, getenv)
	case "--version", "version":
		_, _ = fmt.Fprintf(stdout, "%s %s\n", projectName, version)
		return exitOK
	case "-h", "--help", "help":
		usage(stdout)
		return exitOK
	default:
		_, _ = fmt.Fprintf(stderr, "error: unknown command: %s\n", argv[0])
		usage(stderr)
		return exitUsage
	}
}

// main wires the process into run. It is the only place that reads os.Args,
// os.Stdout, os.Stderr or os.Getenv, and the only place that calls os.Exit.
func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr, os.Getenv))
}
