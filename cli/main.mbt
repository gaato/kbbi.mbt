///|
async fn die(message : String, code~ : Int) -> Unit {
  @stdio.stderr.write("error: " + message + "\n") catch {
    _ => ()
  }
  @sys.exit(code)
}

///|
async fn main {
  let command = parse_command(@env.args()[1:].to_owned()) catch {
    UsageError(message) => {
      die(message, code=2)
      return
    }
  }
  match command {
    Help(usage) => println(usage)
    Version => println("kbbi 0.1.0")
    Lookup(query) => {
      let transport = @http_async.AsyncTransport::new(timeout_ms=10000)
      defer transport.close()
      let result = @kbbi.lookup(transport, query) catch {
        err => {
          die(describe_error(err), code=1)
          return
        }
      }
      println(result.to_json().stringify(indent=2))
    }
  }
}
