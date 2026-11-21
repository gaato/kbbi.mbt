# gaato/kbbi

Look up Indonesian words in [KBBI Daring](https://kbbi.kemendikdasmen.go.id),
the online edition of *Kamus Besar Bahasa Indonesia*, from MoonBit or from a
shell. An entry comes back as typed data, or as JSON from the command:
headwords with homograph numbers, pronunciations, root words and nonstandard
spellings, and each sense's labels, definition, examples and example meanings.
An agent skill for the command is included.

Unofficial, and not affiliated with KBBI or its operator. Results are read
from KBBI Daring's pages.

[Bahasa Indonesia](https://github.com/gaato/kbbi.mbt/blob/main/README.id.md) ·
[日本語](https://github.com/gaato/kbbi.mbt/blob/main/README.ja.md)

## Install

The command needs no install: MoonBit's `moonx` downloads the latest release
and runs it, as below. For the library:

```sh
moon add gaato/kbbi
moon add gaato/mttp
```

## Try it from a shell

```sh
moonx gaato/kbbi/cmd/kbbi makan
moonx gaato/kbbi/cmd/kbbi rumah sakit
moonx gaato/kbbi/cmd/kbbi --help
```

The arguments form one query, joined with spaces, so the second line looks up
the phrase *rumah sakit*. A lookup prints one pretty-printed JSON document.

| Exit code | Meaning |
| --- | --- |
| 0 | Success, including a word KBBI does not have (`found: false`) |
| 1 | A network, status or decoding failure |
| 2 | Invalid arguments |

Errors go to stderr as `error: ...`. Requests time out after 10 seconds.
Please avoid rapid bulk lookups.

An optional moonrun policy limits the command's network access to KBBI. Save
this as `kbbi-policy.json`:

```json
{"net":{"connect":["kbbi.kemendikdasmen.go.id:443"]}}
```

```sh
moonx --experimental-policy kbbi-policy.json gaato/kbbi/cmd/kbbi gemas
```

## Use the library

`lookup` takes a `Client` from `gaato/mttp_core`, so the library imports no
async runtime and builds for wasm, native and js. An executable adds
`gaato/mttp`, whose `@mttp.Client` is the same type, and builds one with
`@mttp.client()`, as `run_lookup` does below. The caller owns and closes the client, and its timeout, retry and
body-limit settings apply to lookups. Reuse one client for several queries.

```mbt check
///|
/// Prints the headword and first definition of each entry for `word`.
async fn print_definitions(client : @mttp.Client, word : String) -> Unit {
  let result = @kbbi.lookup(client, word)
  if !result.found {
    println("\{word}: not in KBBI")
  }
  for entry in result.entries {
    println("\{entry.headword}: \{entry.senses[0].gloss}")
  }
}

///|
/// Builds a client, looks `word` up and closes the client, on mttp's event
/// loop; an executable's `fn main` can call it.
fn run_lookup(word : String) -> Unit {
  @mttp.run(async fn() {
    let client = @mttp.client(timeout_ms=10_000)
    defer client.close()
    print_definitions(client, word)
  })
}

///|
test "the usage example compiles" {
  ignore(print_definitions)
  ignore(run_lookup)
}
```

A word KBBI does not have is not an error: the result has `found: false` and
no entries. `to_json()` converts a result to the same JSON the command prints.

### Parse a saved page

`parse` reads an entry page without any I/O, and `entry_url` gives the page to
save. Use it for tests, or to reread an entry without another request:

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

### Errors

`lookup` raises `KbbiError`:

- `EmptyQuery`: the query is blank after trimming. Nothing is sent.
- `Http`: sending or reading failed. It carries the `TransportError`.
- `Status`: KBBI answered with a non-2xx status.
- `Decode`: the page is not valid UTF-8.

Errors raised by the client's own policies pass through unchanged.

## Packages

| Package | What it is | Targets |
|---|---|---|
| `gaato/kbbi` | The library: `lookup`, `parse`, `entry_url` and the result types | wasm, native, js |
| `gaato/kbbi/cmd/kbbi` | The `kbbi` command and its agent skill | wasm, native |

The [agent skill](https://github.com/gaato/kbbi.mbt/blob/main/cmd/kbbi/SKILL.md)
describes how to run lookups and read the JSON.

## Links

- [Changelog](https://github.com/gaato/kbbi.mbt/blob/main/CHANGELOG.md)
- [Repository](https://github.com/gaato/kbbi.mbt)

## License

Apache-2.0
