package greet

import "testing"

// TestGreeting is the table that defines what a greeting looks like. Every row
// is one decision the renderer makes: pass through, trim, or fall back.
func TestGreeting(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		word   string
		target string
		want   string
	}{
		{name: "plain pair", word: "Hello", target: "Ada", want: "Hello, Ada!"},
		{name: "custom word", word: "Howdy", target: "Grace", want: "Howdy, Grace!"},
		{name: "blank word falls back", word: "", target: "Ada", want: "Hello, Ada!"},
		{name: "whitespace word falls back", word: " \t ", target: "Ada", want: "Hello, Ada!"},
		{name: "word is trimmed", word: "  Hi  ", target: "Ada", want: "Hi, Ada!"},
		{name: "name is trimmed", word: "Hi", target: "  Ada  ", want: "Hi, Ada!"},
		{name: "blank name renders as-is", word: "Hi", target: "", want: "Hi, !"},
		{name: "both blank", word: "", target: "", want: "Hello, !"},
		{name: "multiword name is kept", word: "Hello", target: "Ada Lovelace", want: "Hello, Ada Lovelace!"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			if got := Greeting(tc.word, tc.target); got != tc.want {
				t.Errorf("Greeting(%q, %q) = %q, want %q", tc.word, tc.target, got, tc.want)
			}
		})
	}
}

// TestGreetingHasNoTrailingNewline pins the caller contract: the renderer
// returns a line, it does not print one, so the CLI owns the newline.
func TestGreetingHasNoTrailingNewline(t *testing.T) {
	t.Parallel()

	got := Greeting("Hello", "Ada")
	if len(got) == 0 || got[len(got)-1] == '\n' {
		t.Errorf("Greeting(\"Hello\", \"Ada\") = %q, want no trailing newline", got)
	}
}

// TestGreetingIsPure calls the same input twice: a renderer that cached or read
// state would drift, and the shell/python lanes' equivalents are tested the same
// way.
func TestGreetingIsPure(t *testing.T) {
	t.Parallel()

	first := Greeting("Hey", "Ada")
	second := Greeting("Hey", "Ada")
	if first != second {
		t.Errorf("Greeting is not pure: %q then %q", first, second)
	}
}

// TestDefaultWord pins the fallback literal, because the CLI's usage text and
// both other lanes quote it: changing it here must be a deliberate act with the
// docs moved in the same commit.
func TestDefaultWord(t *testing.T) {
	t.Parallel()

	if DefaultWord != "Hello" {
		t.Errorf("DefaultWord = %q, want %q", DefaultWord, "Hello")
	}
}
