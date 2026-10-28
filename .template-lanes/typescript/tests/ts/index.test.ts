/**
 * Tests for src/index.ts (lane: typescript).
 *
 * Sized to hold the 100% lines/functions/branches/statements gate in
 * vitest.config.ts: every pure renderer, every argument mistake, every switch
 * label, and both sides of every `?? `, `=== ""` and default-parameter branch.
 * The single excluded region is the module entry guard, named in that config
 * file and in src/index.ts itself.
 *
 * Run: npm test          npm run test:coverage
 */

import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  DEFAULT_GREETING_WORD,
  EXIT_OK,
  EXIT_USAGE,
  PROJECT,
  VERSION,
  buildGreeting,
  greet,
  isCliEntry,
  main,
  resolveWord,
  usageText,
} from "@/index";

beforeEach(() => {
  delete process.env.GREETING_WORD;
});

describe("buildGreeting", () => {
  it("renders word, name and bang", () => {
    expect(buildGreeting("Hello", "Ada")).toBe("Hello, Ada!");
  });

  it("trims both arguments", () => {
    expect(buildGreeting("  Howdy  ", "  Grace Hopper  ")).toBe("Howdy, Grace Hopper!");
  });

  it("falls back to the default word when the word is blank", () => {
    expect(buildGreeting("   ", "Ada")).toBe(`${DEFAULT_GREETING_WORD}, Ada!`);
  });

  it("throws on a blank name", () => {
    expect(() => buildGreeting("Hello", "   ")).toThrow("greet needs a name");
  });
});

describe("resolveWord", () => {
  it("uses the default when the variable is absent", () => {
    expect(resolveWord({})).toBe(DEFAULT_GREETING_WORD);
  });

  it("uses the default when the variable is empty", () => {
    expect(resolveWord({ GREETING_WORD: "" })).toBe(DEFAULT_GREETING_WORD);
  });

  it("uses the default when the variable is whitespace only", () => {
    expect(resolveWord({ GREETING_WORD: "   " })).toBe(DEFAULT_GREETING_WORD);
  });

  it("uses the configured word and trims it", () => {
    expect(resolveWord({ GREETING_WORD: "  Howdy  " })).toBe("Howdy");
  });
});

describe("greet", () => {
  it("reads the ambient environment", () => {
    expect(greet("Ada")).toBe("Hello, Ada!");
  });

  it("honours GREETING_WORD", () => {
    process.env.GREETING_WORD = "Howdy";
    expect(greet("Ada")).toBe("Howdy, Ada!");
  });

  it("propagates the blank-name error to library callers", () => {
    expect(() => greet("")).toThrow("greet needs a name");
  });
});

describe("usageText", () => {
  it("names every command, the environment variable and the exit codes", () => {
    const text = usageText();
    expect(text).toContain("greet <name>");
    expect(text).toContain("--version");
    expect(text).toContain("GREETING_WORD");
    expect(text).toContain(PROJECT);
    expect(text).toContain("2  bad arguments");
  });
});

describe("main", () => {
  /** Run main with collecting writers and hand back everything it produced. */
  function capture(argv: string[]): { out: string[]; err: string[]; code: number } {
    const out: string[] = [];
    const err: string[] = [];
    const code = main(
      argv,
      (line: string) => out.push(line),
      (line: string) => err.push(line),
    );
    return { out, err, code };
  }

  it("greet prints one line and returns 0 through injected writers", () => {
    const out: string[] = [];
    const err: string[] = [];
    const code = main(
      ["greet", "Ada"],
      (line: string) => out.push(line),
      (line: string) => err.push(line),
    );
    expect(code).toBe(EXIT_OK);
    expect(out).toEqual(["Hello, Ada!"]);
    expect(err).toEqual([]);
  });

  it("greet reads GREETING_WORD", () => {
    process.env.GREETING_WORD = "Howdy";
    const out: string[] = [];
    const code = main(
      ["greet", "Ada"],
      (line: string) => out.push(line),
      () => undefined,
    );
    expect(code).toBe(EXIT_OK);
    expect(out).toEqual(["Howdy, Ada!"]);
  });

  it("uses the console when no writer is injected", () => {
    const log = vi.spyOn(console, "log").mockImplementation(() => undefined);
    expect(main(["greet", "Ada"])).toBe(EXIT_OK);
    expect(log).toHaveBeenCalledWith("Hello, Ada!");
  });

  it("uses console.error when no error writer is injected", () => {
    const error = vi.spyOn(console, "error").mockImplementation(() => undefined);
    expect(main(["nope"])).toBe(EXIT_USAGE);
    expect(error).toHaveBeenCalledWith("error: unknown command: nope");
  });

  it("rejects greet with no name", () => {
    const out: string[] = [];
    const err: string[] = [];
    const code = main(
      ["greet"],
      (line: string) => out.push(line),
      (line: string) => err.push(line),
    );
    expect(code).toBe(EXIT_USAGE);
    expect(out).toEqual([]);
    expect(err[0]).toContain("greet needs exactly one name");
  });

  it("rejects greet with a blank name", () => {
    const err: string[] = [];
    const code = main(
      ["greet", "   "],
      () => undefined,
      (line: string) => err.push(line),
    );
    expect(code).toBe(EXIT_USAGE);
    expect(err[0]).toContain("greet needs exactly one name");
  });

  it("prints the version for both spellings", () => {
    for (const flag of ["--version", "version"]) {
      const out: string[] = [];
      const code = main(
        [flag],
        (line: string) => out.push(line),
        () => undefined,
      );
      expect(code).toBe(EXIT_OK);
      expect(out).toEqual([`${PROJECT} ${VERSION}`]);
    }
  });

  it("prints usage for all three help spellings", () => {
    for (const flag of ["-h", "--help", "help"]) {
      const out: string[] = [];
      const code = main(
        [flag],
        (line: string) => out.push(line),
        () => undefined,
      );
      expect(code).toBe(EXIT_OK);
      expect(out[0]).toContain("Usage:");
    }
  });

  it("reports no command as a usage error on stderr only", () => {
    const out: string[] = [];
    const err: string[] = [];
    const code = main(
      [],
      (line: string) => out.push(line),
      (line: string) => err.push(line),
    );
    expect(code).toBe(EXIT_USAGE);
    expect(out).toEqual([]);
    expect(err[0]).toBe("error: no command given");
    expect(err[1]).toContain("Usage:");
  });

  it("names an unknown command", () => {
    const result = capture(["frobnicate"]);
    expect(result.err[0]).toBe("error: unknown command: frobnicate");
  });
});

describe("isCliEntry", () => {
  // Built from the project root rather than from `import.meta.url`: under a bundler-
  // backed runner the module's own URL is whatever scheme the runner serves it over,
  // and a test that derives its fixture from that scheme tests the runner.
  const selfPath = resolve(process.cwd(), "src/index.ts");
  const selfUrl = pathToFileURL(selfPath).href;

  it("is false when node was given no script path", () => {
    expect(isCliEntry(selfUrl, undefined)).toBe(false);
  });

  it("is true when argv[1] is this module", () => {
    expect(isCliEntry(selfUrl, selfPath)).toBe(true);
  });

  it("is false when argv[1] names some other file", () => {
    expect(isCliEntry(selfUrl, "/usr/local/bin/something-else.ts")).toBe(false);
  });

  it("is false when the runner handed the module a served URL", () => {
    // The case that used to throw: fileURLToPath rejects a URL that is not file:.
    expect(isCliEntry("http://localhost:5173/src/index.ts", selfPath)).toBe(false);
  });

  it("is false when the module URL is not a URL at all", () => {
    expect(isCliEntry("src/index.ts", selfPath)).toBe(false);
  });
});
