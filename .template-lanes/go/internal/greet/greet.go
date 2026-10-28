// Package greet is the pure string half of the greet command.
//
// Greeting is the one piece of __PROJECT_NAME__ that decides what a greeting
// LOOKS like. It is kept here, alone, for two reasons: it reads no globals, no
// environment and no files, so a test calls it directly and compares a string
// (see greet_test.go, which never spawns a subprocess); and the CLI in
// src/main.go stays a thin argv/exit-code shell over it. When the greeting
// format changes, only this file changes and the assertion that proves it lives
// next to it.
//
// This is the Go spelling of the shell lane's src/lib/greet.sh and the python
// lane's build_greeting(): same fallback, same output, same reason to exist.
package greet

import "strings"

// DefaultWord is the greeting word used when the caller supplies a blank one.
// It is exported so the CLI's usage text and the tests quote the same word the
// renderer falls back to, instead of repeating the literal.
const DefaultWord = "Hello"

// Greeting composes the single greeting line from a word and a name.
//
// Pure: given the same two arguments it always returns the same line, touches no
// state, and never fails. A blank or all-whitespace word falls back to
// DefaultWord, so the caller decides policy and this function only renders; a
// blank name is returned as-is, because validating argv is the caller's job. The
// result carries no trailing newline: the caller decides how it is written.
func Greeting(word, name string) string {
	rendered := strings.TrimSpace(word)
	if rendered == "" {
		rendered = DefaultWord
	}

	return rendered + ", " + strings.TrimSpace(name) + "!"
}
