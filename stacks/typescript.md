# Stack: TypeScript / Node

Applies to TypeScript services and libraries running on Node LTS. Read alongside
`AGENTS.md`; this file only adds what is specific to the stack.

## Language and compiler

- `strict: true` in `tsconfig.json`, plus `noUncheckedIndexedAccess` and
  `exactOptionalPropertyTypes` for new projects. Don't loosen them to make an
  error go away; fix the type.
- No `any`. Use `unknown` at trust boundaries (JSON, environment, network,
  queue messages) and narrow it with a schema validator such as zod.
- Prefer discriminated unions over optional-field bags for state that has
  distinct shapes. Exhaustive `switch` with a `never` check in the default.
- Use `type` imports (`import type`) for type-only imports.
- ESM for new packages. Pin the Node version in `.nvmrc` or `engines`.

## Errors and async

- Throw `Error` subclasses with a stable `name` or `code`, never strings.
- Every promise is awaited, returned, or explicitly handled. Enable the
  `no-floating-promises` lint rule.
- Network calls take an `AbortSignal` with a timeout (`AbortSignal.timeout(ms)`).
- Validate configuration once at startup and fail fast with a clear message.

## Testing

- Vitest (or the project's existing runner). Tests live next to the code as
  `*.test.ts` unless the project already uses a `test/` tree.
- Test behavior through public functions; don't export internals only to test them.
- Use fakes for the clock and randomness instead of sleeping in tests.

## Tooling

- One command each for lint, type-check, test and build, exposed as npm
  scripts (`lint`, `typecheck`, `test`, `build`) so every tool and every
  person runs the same thing.
- Type-check (`tsc --noEmit`) runs in CI separately from the build.
- Lockfile committed; `npm ci` in CI.

## Dependencies

- Prefer the standard library and small, maintained packages. Check the
  last release date and download trend before adding one.
- No new runtime dependency for something a few lines of code can do.
