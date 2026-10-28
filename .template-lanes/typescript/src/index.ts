/**
 * __PROJECT_NAME__ - __PROJECT_DESCRIPTION__
 *
 * The whole CLI, in the shape every file in this lane copies:
 *
 * - pure renderers (`buildGreeting`, `usageText`) that only return strings;
 * - one environment reader (`resolveWord`) that is the only function allowed to
 *   look at `process.env`;
 * - `main`, which takes argv, takes the writers it prints to, and RETURNS an
 *   exit code instead of calling `process.exit`, so a test drives it in-process;
 * - one module-level entry guard, the only side effect in the file, boxed in by
 *   `v8 ignore` markers and described in vitest.config.ts.
 *
 * Exit codes, asserted in tests/ts/index.test.ts:
 *
 * - 0 the command ran
 * - 2 argv was wrong: no command, unknown command, or greet without a name
 */

import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const PROJECT = "__PROJECT_NAME__";
export const VERSION = "0.1.0";
export const DEFAULT_GREETING_WORD = "Hello";
export const GREETING_WORD_ENV = "GREETING_WORD";

export const EXIT_OK = 0;
export const EXIT_USAGE = 2;

/**
 * Render `<word>, <name>!` from two strings.
 *
 * The pure half of the greeting: no environment, no I/O, same arguments in,
 * same string out.
 *
 * @param word - The greeting word. Blank falls back to {@link DEFAULT_GREETING_WORD}.
 * @param name - The name to greet. Surrounding whitespace is stripped.
 * @returns The greeting line, without a trailing newline.
 * @throws If `name` is empty or whitespace only.
 */
export function buildGreeting(word: string, name: string): string {
  const trimmedName = name.trim();
  if (trimmedName === "") {
    throw new Error("greet needs a name, for example: greet Ada");
  }
  const trimmedWord = word.trim();
  return `${trimmedWord === "" ? DEFAULT_GREETING_WORD : trimmedWord}, ${trimmedName}!`;
}

/**
 * Read the greeting word out of an environment record.
 *
 * The record is a parameter, not `process.env`, so a test can pass a literal
 * object instead of mutating global state - and so the one branch that matters
 * (blank means unset) is exercised from both sides.
 *
 * @param env - A `process.env`-shaped record.
 * @returns The configured word, or {@link DEFAULT_GREETING_WORD} when it is
 *   unset, empty or whitespace only.
 */
export function resolveWord(env: Record<string, string | undefined>): string {
  const word = (env[GREETING_WORD_ENV] ?? "").trim();
  return word === "" ? DEFAULT_GREETING_WORD : word;
}

/**
 * Compose the greeting line for `name`, using the configured word.
 *
 * @param name - The name to greet.
 * @returns The greeting line, without a trailing newline.
 * @throws If `name` is empty or whitespace only.
 */
export function greet(name: string): string {
  return buildGreeting(resolveWord(process.env), name);
}

/**
 * Build the help block.
 *
 * @returns The multi-line usage text, without a trailing newline.
 */
export function usageText(): string {
  return [
    `${PROJECT} ${VERSION} - __PROJECT_DESCRIPTION__`,
    "",
    "Usage:",
    `  ${PROJECT} greet <name>`,
    `  ${PROJECT} --version`,
    `  ${PROJECT} --help`,
    "",
    "Environment:",
    `  ${GREETING_WORD_ENV}   word used by "greet" (default: ${DEFAULT_GREETING_WORD})`,
    "",
    "Exit codes:",
    "  0  success",
    "  2  bad arguments",
  ].join("\n");
}

/**
 * Run the CLI and return its exit code.
 *
 * Never calls `process.exit`: an exit code a test can assert is worth ten
 * assertions about a child process. The two writers default to the console and
 * are injected in tests, which is why both call styles appear in the suite.
 *
 * @param argv - The arguments after the program name.
 * @param write - Where a result line goes. Defaults to `console.log`.
 * @param writeErr - Where a diagnostic goes. Defaults to `console.error`.
 * @returns {@link EXIT_OK} when a command ran, {@link EXIT_USAGE} for any argv
 *   mistake.
 */
export function main(
  argv: string[],
  write: (line: string) => void = (line: string) => console.log(line),
  writeErr: (line: string) => void = (line: string) => console.error(line),
): number {
  if (argv.length === 0) {
    writeErr("error: no command given");
    writeErr(usageText());
    return EXIT_USAGE;
  }

  const command: string | undefined = argv[0];
  const rest: string[] = argv.slice(1);

  switch (command) {
    case "--version":
    case "version":
      write(`${PROJECT} ${VERSION}`);
      return EXIT_OK;

    case "-h":
    case "--help":
    case "help":
      write(usageText());
      return EXIT_OK;

    case "greet": {
      const name: string | undefined = rest[0];
      if (name === undefined || name.trim() === "") {
        writeErr(`error: greet needs exactly one name, for example: ${PROJECT} greet Ada`);
        return EXIT_USAGE;
      }
      write(greet(name));
      return EXIT_OK;
    }

    default:
      writeErr(`error: unknown command: ${command}`);
      writeErr(usageText());
      return EXIT_USAGE;
  }
}

/**
 * Decide whether a module is being run as the program.
 *
 * A function rather than an inline comparison so the decision - the only
 * non-trivial thing the entry guard does - is unit-tested instead of excluded.
 *
 * @param moduleUrl - The module's own `import.meta.url`.
 * @param argvPath - `process.argv[1]`, the path node was asked to run.
 * @returns True when both name the same file.
 */
export function isCliEntry(moduleUrl: string, argvPath: string | undefined): boolean {
  if (argvPath === undefined) {
    return false;
  }
  // fileURLToPath throws unless the URL is file:. A runner or bundler that serves the
  // module over http instead answers "not the entry point" the same way a mismatched
  // path does, so the protocol is checked rather than assumed.
  if (!URL.canParse(moduleUrl) || new URL(moduleUrl).protocol !== "file:") {
    return false;
  }
  return fileURLToPath(moduleUrl) === resolve(argvPath);
}

/* v8 ignore start -- the one side effect in the file. It cannot fire under a test
   import (argv[1] is the test runner, not this file) and must not fire there, so
   it is excluded from the gate; every decision it makes lives in isCliEntry and
   main above, both of which are covered. */
if (isCliEntry(import.meta.url, process.argv[1])) {
  process.exitCode = main(process.argv.slice(2));
}
/* v8 ignore stop */
