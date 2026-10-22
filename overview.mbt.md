# gaato/kbbi

An unofficial lookup library, command-line tool, and agent skill for
[KBBI Daring](https://kbbi.kemendikdasmen.go.id), the online edition of the
Indonesian dictionary *Kamus Besar Bahasa Indonesia*. It reads an entry page
and returns typed data: headwords with homograph numbers, pronunciations,
root words and nonstandard spellings, and each sense's labels, definition,
examples, and example meanings.

> **Status**: unofficial. Results are scraped from KBBI Daring; this project
> is not affiliated with KBBI or its operator.

## Install

As a library:

```sh
moon add gaato/kbbi
```

As a command, run the prebuilt executable with MoonBit's `moonx`, which
downloads the latest release:

```sh
moonx gaato/kbbi/cmd/kbbi makan
```

## Usage

`lookup` takes any `gaato/http` transport, so the library itself does no IO
of its own and builds for wasm, native, and js. In an executable, pass
`@http_async.AsyncTransport` from `gaato/http-async`:

```mbt check
///|
/// Prints the headword and first definition of each entry for `word`.
async fn print_definitions(
  transport : &@http.Transport,
  word : String,
) -> Unit raise @kbbi.KbbiError {
  let result = @kbbi.lookup(transport, word)
  if !result.found {
    println("\{word}: not in KBBI")
  }
  for entry in result.entries {
    println("\{entry.headword}: \{entry.senses[0].gloss}")
  }
}

///|
test "print_definitions compiles" {
  ignore(print_definitions)
}
```

`parse` reads a saved entry page without any IO, and `entry_url` gives the
page to save:

```mbt check
///|
test "parse a saved page" {
  let html =
    #|<h2>ma.kan<sup>1</sup></h2>
    #|<ol><li><font color="red"><i><span title="Verba: kata kerja">v</span></i></font>
    #|mengisap:<font color="grey"><i>-- candu</i></font></li></ol>
  let url = @kbbi.entry_url("makan")
  let result = @kbbi.parse(html, query="makan", url~)
  inspect(url, content="https://kbbi.kemendikdasmen.go.id/entri/makan")
  inspect(result.entries[0].headword, content="makan")
  inspect(result.entries[0].senses[0].gloss, content="mengisap")
}
```

A result converts to JSON with `to_json()`; the command prints the same
document.

## Packages

| Package | What it is | Targets |
|---|---|---|
| `gaato/kbbi` | The lookup library: `lookup`, `parse`, `entry_url`, and the result types | wasm, native, js |
| `gaato/kbbi/cmd/kbbi` | The `kbbi` command and its agent skill | wasm, native |

## Errors

`lookup` raises `KbbiError`:

- `EmptyQuery` when the query is blank after trimming; nothing is sent.
- `Http` when the transport fails, carrying the `gaato/http` error.
- `Status` when KBBI answers with a non-2xx status.
- `Decode` when the page is not valid UTF-8.

A word KBBI does not have is not an error: the result has `found: false` and
no entries.

## Run

```sh
moonx gaato/kbbi/cmd/kbbi makan
moonx gaato/kbbi/cmd/kbbi rumah sakit
moonx gaato/kbbi/cmd/kbbi --help
```

Arguments form one query, joined with spaces. A lookup prints one pretty
JSON document, including `found: false` for no match. `--help` and
`--version` print plain text. The exit code is 0 on success, 1 for a
network, status, or decoding failure, and 2 for invalid arguments; errors go
to stderr as `error: ...`. Requests time out after 10 seconds.

An optional moonrun policy limits the command's network access to KBBI. Save
this as `kbbi-policy.json`:

```json
{"net":{"connect":["kbbi.kemendikdasmen.go.id:443"]}}
```

```sh
moonx --experimental-policy kbbi-policy.json gaato/kbbi/cmd/kbbi gemas
```

Please avoid rapid bulk lookups.

## Agent skill

The command's package includes an agent skill,
[`cmd/kbbi/SKILL.md`](https://github.com/gaato/kbbi.mbt/blob/main/cmd/kbbi/SKILL.md),
that tells a coding agent how to run lookups and read the JSON.

## Links

- [Changelog](https://github.com/gaato/kbbi.mbt/blob/main/CHANGELOG.md)
- [Repository](https://github.com/gaato/kbbi.mbt)

## License

Apache-2.0
