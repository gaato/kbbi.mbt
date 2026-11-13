///|
struct TestBackend {
  mut request : @mttp_core.Request?
  mut options : @mttp_core.SendOptions?
  response : @mttp_core.Response
}

///|
impl @mttp_core.Backend for TestBackend with fn send(self, request, options) {
  self.request = Some(request)
  self.options = Some(options)
  self.response
}

///|
fn test_backend(response : @mttp_core.Response) -> TestBackend {
  { request: None, options: None, response, }
}

///|
fn test_client(backend : &@mttp_core.Backend) -> @client.Client {
  @client.Client::new(backend, @sim.FakeClock::new(), timeout_ms=10000)
}

///|
test "lookup sends encoded URL and headers" {
  let backend = test_backend(
    @mttp_core.Response::new(200, body=Bytes(@utf8.encode(gemas_html))),
  )
  let client = test_client(backend)
  defer client.close()
  let result = @driver.run_sync(() => lookup(client, "  GeMas  "))
  assert_eq(result.query, "GeMas")
  assert_eq(result.url, DEFAULT_BASE_URL + "/entri/gemas")
  assert_true(result.found)
  let request = backend.request.unwrap()
  assert_eq(request.meth, @mttp_core.Get)
  assert_eq(request.url, result.url)
  assert_eq(
    request.headers.get("User-Agent"),
    Some("kbbi.mbt/0.4.0 (https://github.com/gaato/kbbi.mbt)"),
  )
  assert_eq(
    request.headers.get("Accept"),
    Some("text/html,application/xhtml+xml"),
  )
  assert_eq(backend.options.unwrap(), {
    timeout_ms: Some(10000),
    body: Exchange(max_bytes=64 * 1024 * 1024),
  })
}

///|
test "lookup rejects empty query before sending" {
  let backend = test_backend(@mttp_core.Response::new(200))
  let client = test_client(backend)
  defer client.close()
  try @driver.run_sync(() => lookup(client, "  \t  ")) catch {
    EmptyQuery => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected EmptyQuery")
  }
  assert_true(backend.request is None)
}

///|
test "lookup maps status and malformed UTF-8" {
  let client = test_client(test_backend(@mttp_core.Response::new(503)))
  defer client.close()
  try @driver.run_sync(() => lookup(client, "gemas")) catch {
    Status(503) => ()
    _ => fail("wrong status error")
  } noraise {
    _ => fail("expected status error")
  }
  let bad_utf8 = test_client(
    test_backend(@mttp_core.Response::new(200, body=Bytes(b"\xff"))),
  )
  defer bad_utf8.close()
  try @driver.run_sync(() => lookup(bad_utf8, "gemas")) catch {
    Decode("malformed UTF-8") => ()
    _ => fail("wrong decode error")
  } noraise {
    _ => fail("expected decode error")
  }
}

///|
test "lookup maps transport failures without retrying" {
  let error = @mttp_core.TransportError(
    kind=Connect,
    phase=Dial,
    detail="offline",
  )
  let mut calls = 0
  let backend = @client.from_fn((_, _) => {
    calls += 1
    raise error
  })
  let client = test_client(backend)
  defer client.close()
  try @driver.run_sync(() => lookup(client, "gemas")) catch {
    Http(@mttp_core.TransportError(kind=Connect, phase=Dial, detail="offline")) =>
      ()
    _ => fail("wrong transport error")
  } noraise {
    _ => fail("expected transport error")
  }
  assert_eq(calls, 1)
}

///|
test "lookup reads and closes a streamed fixture" {
  let d = @driver.Driver::new()
  let bytes = @utf8.encode(gemas_html)
  let feed = @sim.Feed::bytes(d, [bytes[:17].to_owned(), bytes[17:].to_owned()])
  let client = test_client(
    test_backend(
      @mttp_core.Response::new(
        200,
        body=Stream(@mttp_core.StreamBody::new(feed)),
      ),
    ),
  )
  defer client.close()
  let result = d.run(() => lookup(client, "gemas"))
  assert_eq(result, parse(gemas_html, query="gemas", url=entry_url("gemas")))
  assert_eq(feed.closes(), 1)
}

///|
test "lookup closes status bodies without reading them" {
  let d = @driver.Driver::new()
  let feed = @sim.Feed::new(d, [
    Fail(
      @mttp_core.TransportError(kind=Network, phase=Body, detail="do not read"),
    ),
  ])
  let client = test_client(
    test_backend(
      @mttp_core.Response::new(
        503,
        body=Stream(@mttp_core.StreamBody::new(feed)),
      ),
    ),
  )
  defer client.close()
  try d.run(() => lookup(client, "gemas")) catch {
    Status(503) => ()
    _ => fail("status must win over a body error")
  } noraise {
    _ => fail("expected status error")
  }
  assert_eq(feed.reads(), 0)
  assert_eq(feed.closes(), 1)
}

///|
test "lookup maps streamed body failures and closes the body" {
  let d = @driver.Driver::new()
  let error = @mttp_core.TransportError(
    kind=Timeout(ms=10000),
    phase=Body,
    detail="slow",
  )
  let feed = @sim.Feed::new(d, [Chunk(b"<h2>"), Fail(error)])
  let client = test_client(
    test_backend(
      @mttp_core.Response::new(
        200,
        body=Stream(@mttp_core.StreamBody::new(feed)),
      ),
    ),
  )
  defer client.close()
  try d.run(() => lookup(client, "gemas")) catch {
    Http(@mttp_core.TransportError(kind~, phase~, detail~)) =>
      assert_eq((kind, phase, detail), (Timeout(ms=10000), Body, "slow"))
    _ => fail("wrong body error")
  } noraise {
    _ => fail("expected body error")
  }
  assert_eq(feed.closes(), 1)
}

///|
test "lookup respects the client's decoded body limit" {
  let d = @driver.Driver::new()
  let feed = @sim.Feed::bytes(d, [b"123", b"45"])
  let client = @client.Client::new(
    test_backend(
      @mttp_core.Response::new(
        200,
        body=Stream(@mttp_core.StreamBody::new(feed)),
      ),
    ),
    @sim.FakeClock::new(),
    max_body_bytes=4,
  )
  defer client.close()
  try d.run(() => lookup(client, "gemas")) catch {
    Http(@mttp_core.TransportError(kind=TooLarge(limit=4), phase=Body, ..)) =>
      ()
    _ => fail("wrong body limit error")
  } noraise {
    _ => fail("expected body limit error")
  }
  assert_eq(feed.closes(), 1)
}

///|
test "lookup propagates client configuration errors" {
  let backend = test_backend(@mttp_core.Response::new(200))
  let client = @client.Client::new(backend, @sim.FakeClock::new(), total_ms=10)
  defer client.close()
  try @driver.run_sync(() => lookup(client, "gemas")) catch {
    @client.InvalidRequest(..) => ()
    _ => fail("wrong client configuration error")
  } noraise {
    _ => fail("expected client configuration error")
  }
  assert_true(backend.request is None)
}
