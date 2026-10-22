///|
fn encoded_segment(query : String) -> String {
  let hex = "0123456789ABCDEF"
  let result : Array[String] = []
  for byte in @utf8.encode(query) {
    let n = byte.to_int()
    if (n >= 65 && n <= 90) ||
      (n >= 97 && n <= 122) ||
      (n >= 48 && n <= 57) ||
      n == 45 ||
      n == 46 ||
      n == 95 ||
      n == 126 {
      result.push(String::from_array([n.unsafe_to_char()]))
    } else {
      result.push(
        "%" +
        String::from_array([hex[n / 16].to_int().unsafe_to_char()]) +
        String::from_array([hex[n % 16].to_int().unsafe_to_char()]),
      )
    }
  }
  result.join("")
}

///|
/// The entry page URL for `query`: the query is trimmed, lowercased and
/// percent-encoded as one path segment under `<base_url>/entri/`. A trailing
/// `/` on `base_url` is ignored.
pub fn entry_url(
  query : String,
  base_url~ : String = DEFAULT_BASE_URL,
) -> String {
  base_url.trim_end(chars="/").to_owned() +
  "/entri/" +
  encoded_segment(query.trim().to_owned().to_lower())
}

///|
/// Looks up `query` on KBBI Daring: trims it, sends one GET request for its
/// `entry_url` through `transport`, and parses the page with `parse`. A word
/// KBBI does not have gives `found: false`, not an error.
///
/// Raises `EmptyQuery` for a blank query (before any request), `Http` when
/// the transport fails, `Status` for a non-2xx response, and `Decode` when
/// the body is not valid UTF-8.
pub async fn lookup(
  transport : &@http.Transport,
  query : String,
  base_url~ : String = DEFAULT_BASE_URL,
) -> LookupResult raise KbbiError {
  let trimmed = query.trim().to_owned()
  if trimmed == "" {
    raise EmptyQuery
  }
  let url = entry_url(trimmed, base_url~)
  let request = @http.Request::get(url)
    .header("User-Agent", "kbbi.mbt/0.1.6 (https://github.com/gaato/kbbi.mbt)")
    .header("Accept", "text/html,application/xhtml+xml")
  let response = transport.send(request) catch { err => raise Http(err) }
  if !response.is_success() {
    raise Status(response.status)
  }
  let body = response.text() catch { _ => raise Decode("malformed UTF-8") }
  parse(body, query=trimmed, url~)
}
