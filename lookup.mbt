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
/// Looks up `query` on KBBI Daring: trims it, sends a GET request for its
/// `entry_url` through `client`, and parses the page with `parse`. A word
/// KBBI does not have gives `found: false`, not an error.
///
/// Raises `EmptyQuery` for a blank query (before any request), `Http` when
/// the transport fails, `Status` for a non-2xx response, and `Decode` when
/// the body is not valid UTF-8. Other client policy errors propagate unchanged.
/// The caller owns the client; its policies and body limits apply to the call.
pub async fn lookup(
  client : @client.Client,
  query : String,
  base_url~ : String = DEFAULT_BASE_URL,
) -> LookupResult {
  let trimmed = query.trim().to_owned()
  if trimmed == "" {
    raise EmptyQuery
  }
  let url = entry_url(trimmed, base_url~)
  // Select before reading so an error status wins over an unreadable body.
  let reader : @client.ResponsePlan[Result[Bytes, Int32], @client.Buffered] = @client.from_head(head => {
      if @http.is_success(head.status) {
        @client.ResponsePlan::new((_, bytes) => Ok(bytes))
      } else {
        @client.ignore_body().any_status().map(_ => Err(head.status))
      }
    },
  )
  let request = @client.get(url)
    .header("User-Agent", "kbbi.mbt/0.2.0 (https://github.com/gaato/kbbi.mbt)")
    .header("Accept", "text/html,application/xhtml+xml")
    .response(reader)
  let response = client.send(request) catch {
    @http.TransportError(..) as err => raise Http(err)
    err => raise err
  }
  let bytes = match response.body {
    Ok(bytes) => bytes
    Err(status) => raise Status(status)
  }
  let body = @utf8.decode(bytes) catch { _ => raise Decode("malformed UTF-8") }
  parse(body, query=trimmed, url~)
}
