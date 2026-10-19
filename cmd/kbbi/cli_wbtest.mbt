///|
test "help and version" {
  guard parse_command(["--help"]) is Help(help) else { fail("help") }
  assert_true(help.contains("Look up Indonesian words"))
  assert_true(parse_command(["-h"]) is Help(_))
  assert_true(parse_command(["--version"]) is Version)
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
