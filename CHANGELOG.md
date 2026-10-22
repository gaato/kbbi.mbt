# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- **The README has sections and a compile-checked example.** It covers
  installing, a `lookup` and an offline `parse` example that `moon test`
  compiles and runs, the packages, errors, the command, and links. The
  README and the agent skill run `moonx gaato/kbbi/cmd/kbbi` without a
  version, which takes the latest release, and write shell examples for
  `sh`. Every public declaration has a doc comment.
- The command's internal `Command` and `UsageError` types are private; they
  were never usable from outside the executable.
- Built on `gaato/http` 0.5.0, `gaato/http-async` 0.5.0 and `moonbitlang/x`
  0.5.6, and tested with MoonBit 0.10.16. The generated `.mbti` files spell
  `Int` as `Int32`, the same type.

## [0.1.6] - 2026-10-19

- The command moved from `gaato/kbbi/cli` to `gaato/kbbi/cmd/kbbi`.

## [0.1.5] - 2026-10-19

- Built on `gaato/http` 0.4.0 and `gaato/http-async` 0.4.1; the command
  reports network and proxy failures with their own messages.

## [0.1.4] - 2026-10-16

- Built on newer `gaato/http`, `gaato/http-async` and `moonbitlang/async`.

## [0.1.3] - 2026-10-15

- `Entry::nonstandard_forms` lists the spellings KBBI marks "bentuk tidak
  baku", which no longer leak into the headword.

## [0.1.2] - 2026-09-29

- Homograph numbers on root words no longer become the entry's homograph.

## [0.1.1] - 2026-09-29

- The agent skill moved into the command's package, where mooncakes finds it.

## [0.1.0] - 2026-09-29

- First release: the KBBI lookup library, the `kbbi` command, and its agent
  skill.

[Unreleased]: https://github.com/gaato/kbbi.mbt/commits/main
