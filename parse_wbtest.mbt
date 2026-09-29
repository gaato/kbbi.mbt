///|
fn fixture(html : String, query : String) -> LookupResult {
  parse(html, query~, url=entry_url(query))
}

///|
test "makan entries, labels, examples, and meanings" {
  let result = fixture(makan_html, "makan")
  assert_true(result.found)
  assert_eq(result.entries.length(), 2)
  let first = result.entries[0]
  assert_eq(first.headword, "makan")
  assert_eq(first.homograph, Some(1))
  assert_eq(first.senses.length(), 15)
  let sense = first.senses[0]
  assert_eq(sense.labels, [
    { code: "v", name: "Verba", description: "kata kerja", },
  ])
  assert_eq(
    sense.gloss,
    "memasukkan makanan pokok ke dalam mulut serta mengunyah dan menelannya",
  )
  assert_eq(sense.examples, [
    { text: "mereka -- tiga kali sehari", meaning: None, },
  ])
  assert_eq(first.senses[5].examples.length(), 2)
  assert_eq(first.senses[10].examples, [
    { text: "layarnya tidak --", meaning: Some("tidak memperoleh angin"), },
    { text: "sauhnya dapat --", meaning: Some("mencapai dasar laut"), },
  ])
  assert_true(!first.senses[10].gloss.contains("angin"))
  assert_eq(first.senses[12].labels, [
    { code: "v", name: "Verba", description: "kata kerja", },
    { code: "ki", name: "kiasan", description: "", },
  ])
  let second = result.entries[1]
  assert_eq(second.homograph, Some(2))
  assert_eq(second.senses.length(), 1)
  assert_eq(second.senses[0].labels, [
    { code: "n", name: "Nomina", description: "kata benda", },
    { code: "Tas", name: "Tasawuf", description: "-", },
  ])
}

///|
test "gemas pronunciation and JSON schema" {
  let result = fixture(gemas_html, "gemas")
  assert_eq(result.entries.length(), 1)
  assert_eq(result.entries[0].headword, "gemas")
  assert_eq(result.entries[0].pronunciation, Some("/gêmas/"))
  assert_eq(result.entries[0].homograph, None)
  json_inspect(result, content={
    "found": true,
    "query": "gemas",
    "url": "https://kbbi.kemendikdasmen.go.id/entri/gemas",
    "entries": [
      {
        "headword": "gemas",
        "pronunciation": "/gêmas/",
        "root_words": [],
        "senses": [
          {
            "labels": [
              {
                "code": "a",
                "name": "Adjektiva",
                "description": "kata yang menjelaskan nomina atau pronomina",
              },
            ],
            "gloss": "sangat jengkel (marah) dalam hati",
            "examples": [
              {
                "text": "saya sangat -- pada anak itu karena selalu mengotori lantai",
              },
            ],
          },
          {
            "labels": [
              {
                "code": "a",
                "name": "Adjektiva",
                "description": "kata yang menjelaskan nomina atau pronomina",
              },
            ],
            "gloss": "sangat suka (cinta) bercampur jengkel; jengkel-jengkel cinta",
            "examples": [{ "text": "-- aku melihat anak ini" }],
          },
        ],
      },
    ],
  })
}

///|
test "root word and phrase headword" {
  let punya = fixture(mempunyai_html, "mempunyai")
  assert_eq(punya.entries[0].headword, "mempunyai")
  assert_eq(punya.entries[0].root_words, ["punya"])
  // The root link is `lari<sup>1</sup>`; its homograph number belongs to the root.
  let lari = fixture(berlari_html, "berlari")
  assert_eq(lari.entries[0].headword, "berlari")
  assert_eq(lari.entries[0].root_words, ["lari"])
  assert_eq(lari.entries[0].homograph, None)
  let rumah = fixture(rumah_sakit_html, "Rumah Sakit")
  assert_eq(rumah.entries[0].headword, "rumah sakit")
  assert_true(entry_url("Rumah Sakit").has_suffix("/entri/rumah%20sakit"))
}

///|
test "not found, empty heading, URL encoding" {
  let result = fixture(xyzqwe_html, "xyzqwe")
  assert_true(!result.found)
  assert_eq(result.entries.length(), 0)
  assert_eq(
    entry_url("  A/B é  ", base_url="https://example.test///"),
    "https://example.test/entri/a%2Fb%20%C3%A9",
  )
  let no_senses = parse("<h2>foo</h2><h4>other</h4>", query="foo", url="u")
  assert_true(!no_senses.found)
}

///|
test "first sibling sense list and invalid homograph" {
  let result = parse(
    "<h2>te.st<sup>x</sup></h2><div><ol><li>nested</li></ol></div><ul><li>first</li></ul><ol><li>later</li></ol>",
    query="test",
    url="u",
  )
  assert_eq(result.entries.length(), 1)
  assert_eq(result.entries[0].headword, "test")
  assert_eq(result.entries[0].homograph, None)
  assert_eq(result.entries[0].senses.length(), 1)
  assert_eq(result.entries[0].senses[0].gloss, "first")
}
