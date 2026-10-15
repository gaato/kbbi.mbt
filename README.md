# kbbi.mbt

Unofficial MoonBit lookup library and CLI for KBBI Daring, with an agent skill in [cli/SKILL.md](cli/SKILL.md). It parses dictionary entries into typed data, including homographs, pronunciations, root words, nonstandard spellings, labels, definitions, examples, and example meanings.

## Library

Import `gaato/kbbi` and provide any `gaato/http` transport. For an asynchronous executable using `gaato/http-async`:

```moonbit
let transport = @http_async.AsyncTransport::new(timeout_ms=10000)
defer transport.close()
let result = @kbbi.lookup(transport, "rumah sakit")
println(result.to_json().stringify(indent=2))
```

`lookup` trims the query, sends one GET request, and raises `KbbiError` for empty input, transport failures, non-2xx status, or malformed UTF-8. `parse(html, query~, url~)` is pure and can parse saved HTML. `entry_url` lowercases and percent-encodes a trimmed query as one path segment. The library supports wasm, native, and js.

## CLI

```fish
moonx gaato/kbbi/cli@0.1.2 makan
moonx gaato/kbbi/cli@0.1.2 rumah sakit
moonx gaato/kbbi/cli@0.1.2 --help
moonx --experimental-policy cli/kbbi-policy.json gaato/kbbi/cli@0.1.2 gemas
```

Arguments form one query, joined with spaces. Successful lookups print one pretty JSON document, including `found: false` for no match. Help and version are plain text. Exit codes: 0 success, 1 runtime failure, 2 usage error. Runtime and usage errors print `error: ...` to stderr. The CLI supports wasm and native.

## Develop

Use `moon` on PATH with the version in `moonbit-version`. Tests use embedded copies of `testdata/*.html` and make no network requests. Regenerate those copies after updating the source fixtures with `moon run tools/regen_fixtures.mbtx` followed by `moon fmt`.

```fish
moon fmt
moon info
moon check --target wasm --deny-warn
moon test --target wasm
moon build --target wasm
moon check --target native --deny-warn
moon test --target native
moon build --target native
moon test --target js --package gaato/kbbi
```

The live KBBI site is not exercised by these offline tests. The results are scraped from KBBI Daring; this project is not affiliated with KBBI or its operator. Avoid rapid bulk lookups.

Licensed under Apache-2.0; see [LICENSE](LICENSE).
