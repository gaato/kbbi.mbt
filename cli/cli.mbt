///|
suberror UsageError {
  UsageError(String)
}

///|
enum Command {
  Help(String)
  Version
  Lookup(String)
} derive(Debug, Eq)

///|
fn describe_error(err : Error) -> String {
  match err {
    @kbbi.EmptyQuery => "query must not be empty"
    @kbbi.Http(@http.Connect(message)) => "connection failed: \{message}"
    @kbbi.Http(@http.Timeout(ms)) => "request timed out after \{ms} ms"
    @kbbi.Http(@http.Protocol(message)) => "HTTP protocol error: \{message}"
    @kbbi.Status(code) => "KBBI returned HTTP \{code}"
    @kbbi.Decode(message) => "could not decode the response: \{message}"
    _ => err.to_string()
  }
}

///|
fn argument_error(err : Error) -> String {
  let message = err.to_string()
  let first_line = match message.split_once("\n") {
    Some((line, _)) => line.to_owned()
    None => message
  }
  match first_line.strip_prefix("error: ") {
    Some(rest) => rest.to_owned()
    None => first_line
  }
}

///|
fn build_cli() -> @argparse.Command {
  @argparse.Command(
    "kbbi",
    about="Look up Indonesian words in KBBI Daring.",
    version="0.1.4",
    positionals=[
      @argparse.PositionArg(
        "words",
        about="Word or phrase to look up.",
        num_args=@argparse.ValueRange(lower=1),
        allow_hyphen_values=false,
      ),
    ],
  )
}

///|
fn parse_command(argv : Array[String]) -> Command raise UsageError {
  if argv == ["--help"] || argv == ["-h"] {
    return Help(build_cli().render_help())
  }
  if argv == ["--version"] {
    return Version
  }
  let matches = build_cli().parse(argv~, env={}) catch {
    err => raise UsageError(argument_error(err))
  }
  let words = match matches.values.get("words") {
    Some(values) => values
    None => raise UsageError("missing word")
  }
  let query = words.join(" ").trim().to_owned()
  if query == "" {
    raise UsageError("empty query")
  }
  Lookup(query)
}
