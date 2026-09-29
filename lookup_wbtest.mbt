///|
struct TestTransport {
  mut request : @http.Request?
  response : @http.Response
}

///|
impl @http.Transport for TestTransport with fn send(self, request) {
  self.request = Some(request)
  self.response
}

///|
impl @http.Transport for TestTransport with fn send_stream(_self, _request) {
  raise @http.HttpError::Protocol("streaming unsupported in test")
}

///|
async test "lookup sends encoded URL and headers" {
  let transport = TestTransport::{
    request: None,
    response: {
      status: 200,
      headers: @http.Headers::new(),
      body: @utf8.encode(gemas_html),
    },
  }
  let result = lookup(transport, "  GeMas  ")
  assert_eq(result.query, "GeMas")
  assert_eq(result.url, DEFAULT_BASE_URL + "/entri/gemas")
  assert_true(result.found)
  let request = transport.request.unwrap()
  assert_eq(request.http_method, "GET")
  assert_eq(request.url, result.url)
  assert_eq(
    request.headers.get("User-Agent"),
    Some("kbbi.mbt/0.1.0 (https://github.com/gaato/kbbi.mbt)"),
  )
  assert_eq(
    request.headers.get("Accept"),
    Some("text/html,application/xhtml+xml"),
  )
}

///|
async test "lookup rejects empty query before sending" {
  let transport = TestTransport::{
    request: None,
    response: { status: 200, headers: @http.Headers::new(), body: b"", },
  }
  try lookup(transport, "  \t  ") catch {
    EmptyQuery => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected EmptyQuery")
  }
  assert_eq(transport.request, None)
}

///|
async test "lookup maps status and malformed UTF-8" {
  let transport = TestTransport::{
    request: None,
    response: { status: 503, headers: @http.Headers::new(), body: b"", },
  }
  try lookup(transport, "gemas") catch {
    Status(503) => ()
    _ => fail("wrong status error")
  } noraise {
    _ => fail("expected status error")
  }
  let bad_utf8 = TestTransport::{
    request: None,
    response: {
      status: 200,
      headers: @http.Headers::new(),
      body: Bytes::from_array([0xff]),
    },
  }
  try lookup(bad_utf8, "gemas") catch {
    Decode(_) => ()
    _ => fail("wrong decode error")
  } noraise {
    _ => fail("expected decode error")
  }
}
