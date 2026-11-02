# Agent notes

Instructions for anyone (human or coding agent) changing this repository.

## Layout

Flutter monorepo (a pub workspace): the pure-Dart engine lives in
`packages/interval_core`, shared Flutter UI in `packages/interval_kit`,
music and the media session in `packages/interval_media`, test helpers in
`packages/interval_testing`, the apps in `apps/tabata` and `apps/walking`.
Dependencies only point down — read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
before touching the engine.

## Commands

Run from the repository root unless noted:

| Task | Command |
|---|---|
| Format | `dart format .` |
| Analyze | `flutter analyze` |
| Test the engine | `cd packages/interval_core && dart test` |
| Test a Flutter package or app | `cd <dir> && flutter test` |
| Regenerate localizations | `flutter gen-l10n` in `packages/interval_kit`, `apps/tabata`, `apps/walking` |
| Regenerate README screenshots | `cd apps/<app> && flutter test --tags screenshots --run-skipped` |

CI runs the same checks; keep them green.

## Conventions

- Commit messages follow Conventional Commits, e.g. `feat(kit): scale the
  countdown ring`; types and scopes are listed in [CONTRIBUTING.md](CONTRIBUTING.md).
- Strings live in `.arb` files and the generated localizations are committed:
  run `gen-l10n` after editing an `.arb` file and commit the diff.
- After changing how a screen looks, regenerate the README screenshots.
- Shared first: anything both apps need goes into a package, not into an app.
  New engine logic belongs in `interval_core` with tests there.

## Working style

Work in small steps: split a large feature into small self-contained
commits, each keeping the checks above green. Aim for diffs of at most
~200 lines per commit — a guideline, not a hard rule; when a step must be
bigger, say why in the commit message. Never hand the repository over in a
broken state.
