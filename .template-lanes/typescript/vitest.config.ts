import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    // Must match the "@/*" paths entry in tsconfig.json, or the typechecker and
    // the runner disagree about what `@/index` means.
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  test: {
    // jsdom, not node: the lane is written for a browser-shaped global object,
    // so a test that reaches for `window` or `document` behaves the same here as
    // it will in the consumer's environment.
    environment: "jsdom",
    include: ["tests/**/*.test.ts"],
    globals: false,
    restoreMocks: true,
    unstubEnvs: true,
    unstubGlobals: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      reportsDirectory: "coverage",
      // Only shipped code is measured, and only all of it: `include` names the
      // tree explicitly so a file nobody imports still shows up as 0% instead of
      // quietly never entering the denominator. That is what makes the 100 below
      // a statement about the whole lane rather than about the files that
      // happened to be imported.
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.d.ts"],
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100,
      },
    },
  },
});
