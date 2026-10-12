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
pub fn entry_url(
  query : String,
  base_url~ : String = DEFAULT_BASE_URL,
) -> String {
  base_url.trim_end(chars="/").to_owned() +
  "/entri/" +
  encoded_segment(query.trim().to_owned().to_lower())
}

///|
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
    .header("User-Agent", "kbbi.mbt/0.1.2 (https://github.com/gaato/kbbi.mbt)")
    .header("Accept", "text/html,application/xhtml+xml")
  let response = transport.send(request) catch { err => raise Http(err) }
  if !response.is_success() {
    raise Status(response.status)
  }
  let body = response.text() catch { _ => raise Decode("malformed UTF-8") }
  parse(body, query=trimmed, url~)
}
