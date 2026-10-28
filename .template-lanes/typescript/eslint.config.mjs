// eslint.config.mjs - ESLint 9 flat config for the typescript lane.
//
// Flat config, not .eslintrc: ESLint 9 reads this file and nothing else, so
// there is no legacy file for a contributor's editor to pick up and disagree
// with. `npm run lint` passes --max-warnings 0, so a new warning is a build
// failure the day it appears.

import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["coverage/**", "dist/**", "docs/api/**", "node_modules/**"],
  },

  js.configs.recommended,

  // `recommended` (not recommendedTypeChecked): the type-checked rule set needs
  // a program per file and duplicates what `npm run typecheck` already does with
  // tsc. Type errors belong to tsc; this file owns style and real bug shapes.
  ...tseslint.configs.recommended,

  {
    files: ["**/*.ts"],
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: "module",
    },
    rules: {
      // Pinned to error rather than warn: `any` is how a typed boundary quietly
      // stops being typed, and a template should not start with a rule you can
      // ship past.
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/consistent-type-imports": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
    },
  },

  {
    // The config files themselves, linted as node scripts so a typo in this
    // file's own JS is caught by the same job that lints the source.
    files: ["**/*.{js,mjs,cjs}"],
    languageOptions: {
      globals: { ...globals.node },
    },
  },
);
