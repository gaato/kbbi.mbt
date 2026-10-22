# Development

- Use `moon` on PATH and the toolchain pinned by `moonbit-version`.
- The root package is the library for wasm, native, and js. `cmd/kbbi/` is the executable for wasm and native. Keep parsing pure in `parse.mbt`, HTTP in `lookup.mbt`, CLI argument handling in `cmd/kbbi/cli.mbt`, and process IO in `cmd/kbbi/main.mbt`.
- Run the checks below before handoff. Review generated `pkg.generated.mbti` files; do not edit them by hand.
- Keep tests offline. `testdata/*.html` is the source of truth, fetched on 2026-09-29. `fixtures_wbtest.mbt` embeds those pages for wasm and js tests. After changing any fixture, run `moon run tools/regen_fixtures.mbtx` and `moon fmt` from the repository root, then inspect the fixture tests and update the gemas JSON snapshot only for intentional schema or parsing changes. The tests never reach the live KBBI site, so a change in its HTML shows up only in a manual lookup.
- Inspect dependency APIs through `.mooncakes/*/pkg.generated.mbti`; do not modify `.mooncakes/`.
- Library non-test code must not import an async runtime. CLI parsing must take explicit argv in tests. Data commands print one pretty JSON document. Help and version are text. Runtime errors exit 1; usage errors exit 2; stderr errors start with `error: `.
- The agent skill lives in `cmd/kbbi/SKILL.md` because mooncakes indexes a skill from the executable package directory. Keep it concise and agent-directed. Write shell examples in it and the README as `sh`, not fish: they are public documents that people and agents paste into whatever shell they use, so POSIX syntax is the one that works everywhere.
- A release changes the version in `moon.mod`, the `version=` of the command in `cmd/kbbi/cli.mbt`, the `kbbi <version>` line in `cmd/kbbi/main.mbt`, and the `User-Agent` in `lookup.mbt` with its assertion in `lookup_wbtest.mbt`, and turns `## [Unreleased]` in `CHANGELOG.md` into the version heading. `--version` and the User-Agent print these copies, so a missed one ships the old version string. The README and SKILL.md run `moonx` without a version, which takes the latest release, so they do not change.
- Never commit secrets. Do not run VCS commands or publish without the user's request. Avoid live requests during tests.

## Checks

```sh
moon fmt
moon info
moon check --target wasm --deny-warn
moon test --target wasm
moon build --target wasm
moon check --target native --deny-warn
moon test --target native
moon build --target native
moon test --target js --package gaato/kbbi
moon run scripts/docs_audit.mbtx
```

## Documentation

- `overview.mbt.md` (linked as `README.md`) is for people visiting the module page: what the module does, how to install and use it, errors, and links. mooncakes.io renders it as the module page, so development notes such as these checks belong here, not there.
- Its `mbt check` examples compile as tests of the root package; keep them compiling rather than switching them to `nocheck`, so the page cannot drift from the API.
- Links in published files are absolute URLs, because mooncakes.io serves them away from the repository. Files only the repository needs go in `.moonignore`, which also tells the docs audit that they are not published.
- Run `moon run scripts/docs_audit.mbtx` after changing docs or public declarations. `scripts/docs_audit.mbtx` is shared by every gaato MoonBit repository: copy it from gaato/discord.mbt rather than editing it here, and keep this repository's exceptions in `scripts/docs_audit.json` and `scripts/docs_audit.allow`.
- Record user-visible changes under `## [Unreleased]` in `CHANGELOG.md`; it is the history the README links to.
