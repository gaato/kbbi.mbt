# Development

- Use `moon` on PATH and the toolchain pinned by `moonbit-version`.
- The root package is the library for wasm, native, and js. `cli/` is the executable for wasm and native. Keep parsing pure in `parse.mbt`, HTTP in `lookup.mbt`, CLI argument handling in `cli/cli.mbt`, and process IO in `cli/main.mbt`.
- Run `moon fmt`, `moon info`, then `moon check --deny-warn`, `moon test`, and `moon build` for both wasm and native. Run `moon test --target js --package gaato/kbbi` for the root library. Review generated `pkg.generated.mbti` files; do not edit them by hand.
- Keep tests offline. `testdata/*.html` is the source of truth, fetched on 2026-09-29. `fixtures_wbtest.mbt` embeds those pages for wasm and js tests. After changing any fixture, run `moon run tools/regen_fixtures.mbtx` and `moon fmt` from the repository root, then inspect the fixture tests and update the gemas JSON snapshot only for intentional schema or parsing changes.
- Inspect dependency APIs through `.mooncakes/*/pkg.generated.mbti`; do not modify `.mooncakes/`.
- Library non-test code must not import an async runtime. CLI parsing must take explicit argv in tests. Data commands print one pretty JSON document. Help and version are text. Runtime errors exit 1; usage errors exit 2; stderr errors start with `error: `.
- The agent skill lives in `cli/SKILL.md` because mooncakes indexes a skill from the executable package directory. Keep it concise and agent-directed. Interactive commands use fish syntax.
- Never commit secrets. Do not run VCS commands or publish without the user's request. Avoid live requests during tests.
