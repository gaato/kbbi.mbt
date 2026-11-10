///|
/// Prints `error: message` on stderr and exits with `code`.
fn[T] die(message : String, code~ : Int32) -> T {
  eprintln("error: " + message)
  @env.exit(code)
}

///|
async fn main {
  let command = parse_command(@env.args()[1:].to_owned()) catch {
    UsageError(message) => die(message, code=2)
  }
  match command {
    Help(text) | Version(text) => println(text)
    Lookup(query) => {
      let client = @client.Client::new(
        @backend.AsyncBackend::new(),
        @runtime.AsyncClock::new(),
        timeout_ms=10000,
        timer=@runtime.ClockTimer::new(),
      )
      defer client.close()
      let result = @lib.lookup(client, query) catch {
        err => die(describe_error(err), code=1)
      }
      println(result.to_json().stringify(indent=2))
    }
  }
}
