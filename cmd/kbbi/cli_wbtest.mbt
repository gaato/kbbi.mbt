///|
test "help and version" {
  guard parse_command(["--help"]) is Help(help) else { fail("help") }
  assert_true(help.contains("Look up Indonesian words"))
  assert_true(parse_command(["-h"]) is Help(_))
  assert_true(parse_command(["--version"]) is Version("kbbi 0.2.0"))
  assert_true(parse_command(["-V"]) is Version("kbbi 0.2.0"))
}

///|
test "help and version win over words wherever they appear" {
  for argv in [["rumah", "--help"], ["-h", "x"], ["rumah", "sakit", "-h"]] {
    let line = argv.join(" ")
    guard parse_command(argv) is Help(help) else { fail("help: \{line}") }
    assert_true(help.contains("Usage: kbbi"), msg=line)
    assert_false(help.has_suffix("\n"), msg=line)
  }
  assert_true(parse_command(["rumah", "--version"]) is Version("kbbi 0.2.0"))
}

///|
test "a literal --help after the separator is a word" {
  assert_true(parse_command(["--", "--help"]) is Lookup("--help"))
}

///|
test "multiple words and literal option after separator" {
  assert_true(parse_command(["Rumah", "Sakit"]) is Lookup("Rumah Sakit"))
  assert_true(parse_command(["--", "--literal"]) is Lookup("--literal"))
}

///|
test "usage errors" {
  for argv in [[], ["--unknown"], ["   "]] {
    try parse_command(argv) catch {
      UsageError(_) => continue
    } noraise {
      _ => fail("expected usage error")
    }
  }
}

///|
async test "transport diagnostics retain the CLI messages" {
  let cases : Array[(@http.Kind, String, String)] = [
    (Connect, "offline", "connection failed: offline"),
    (Timeout(ms=10000), "slow", "request timed out after 10000 ms"),
    (Network, "reset", "network error: reset"),
    (Protocol, "bad head", "HTTP protocol error: bad head"),
    (
      Proxy(status=407),
      "authenticate",
      "proxy refused (HTTP 407): authenticate",
    ),
  ]
  for (kind, detail, expected) in cases {
    let client = @client.Client::new(
      @client.from_fn((_, _) => {
        raise @http.TransportError(kind~, phase=Unknown, detail~)
      }),
      @runtime.AsyncClock::new(),
    )
    defer client.close()
    let message = try @lib.lookup(client, "gemas") catch {
      err => describe_error(err)
    } noraise {
      _ => fail("expected transport error")
    }
    assert_eq(message, expected)
  }
}
