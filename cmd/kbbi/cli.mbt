///|

///|
priv suberror UsageError {
  UsageError(String)
}

///|
/// The version `--version` reports. scripts/gates.sh checks that it equals
/// `version` in moon.mod.
let version : String = "0.4.0"

///|
/// What the arguments ask for. `Help` and `Version` carry the text to print,
/// so parsing never prints or exits.
priv enum Command {
  Help(String)
  Version(String)
  Lookup(String)
}

///|
fn describe_error(err : Error) -> String {
  match err {
    @lib.EmptyQuery => "query must not be empty"
    @lib.Http(TransportError(kind=Connect, detail=message, ..)) =>
      "connection failed: \{message}"
    @lib.Http(TransportError(kind=Timeout(ms~), ..)) =>
      "request timed out after \{ms} ms"
    @lib.Http(TransportError(kind=Network, detail=message, ..)) =>
      "network error: \{message}"
    @lib.Http(TransportError(kind=Protocol, detail=message, ..)) =>
      "HTTP protocol error: \{message}"
    @lib.Http(TransportError(kind=Proxy(status~), detail=message, ..)) =>
      "proxy refused (HTTP \{status}): \{message}"
    @lib.Http(error) => error.message()
    @lib.Status(code) => "KBBI returned HTTP \{code}"
    @lib.Decode(message) => "could not decode the response: \{message}"
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
    version~,
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
  let matches = match build_cli().parse_outcome(argv~) {
    Parsed(matches) => matches
    Help(text) => return Help(text)
    Version(text) => return Version("kbbi \{text}")
    Failed(err) => raise UsageError(argument_error(err))
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
