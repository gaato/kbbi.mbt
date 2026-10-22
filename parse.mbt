///|
fn normalize(raw : String) -> String {
  let parts : Array[String] = []
  let mut space = false
  for c in raw {
    if c.is_whitespace() {
      space = parts.length() > 0
    } else {
      if space {
        parts.push(" ")
      }
      parts.push("\{c}")
      space = false
    }
  }
  parts.join("")
}

///|
fn attribute(node : @dom.Node, key : String) -> String {
  match node.attrs().get(key) {
    Some(Some(value)) => value
    _ => ""
  }
}

///|
/// Whether `node` matches `excluded`: tag names, `span.<class>`, or `<font>` colors.
fn is_excluded(node : @dom.Node, excluded : Array[String]) -> Bool {
  excluded.contains(node.name()) ||
  (
    node.name() == "span" &&
    excluded.contains("span." + attribute(node, "class"))
  ) ||
  (
    node.name() == "font" &&
    excluded.contains(attribute(node, "color").to_lower())
  )
}

///|
fn text_except(node : @dom.Node, excluded : Array[String]) -> String {
  if node.kind() == Text {
    return node.data()
  }
  if is_excluded(node, excluded) {
    return ""
  }
  let pieces : Array[String] = []
  for child in node.children() {
    pieces.push(text_except(child, excluded))
  }
  pieces.join("")
}

///|
fn node_text(node : @dom.Node) -> String {
  normalize(text_except(node, []))
}

///|
/// Returns the first descendant element named `name`, skipping excluded subtrees.
fn first_element_except(
  node : @dom.Node,
  name : String,
  excluded : Array[String],
) -> @dom.Node? {
  for child in node.children() {
    if child.kind() == Text || is_excluded(child, excluded) {
      continue
    }
    if child.name() == name {
      return Some(child)
    }
    if first_element_except(child, name, excluded) is Some(found) {
      return Some(found)
    }
  }
  None
}

///|
fn parse_headword(h2 : @dom.Node, senses : Array[Sense]) -> Entry {
  // A root link carries its own homograph number (`lari<sup>1</sup>`).
  let roots : Array[String] = []
  for link in @html_parser.query(h2, "span.rootword a") {
    roots.push(normalize(text_except(link, ["sup"])))
  }
  let pronunciation = match @html_parser.query_one(h2, "span.syllable") {
    Some(span) => Some(node_text(span))
    None => None
  }
  let homograph = match
    first_element_except(h2, "sup", ["span.rootword", "small"]) {
    Some(sup) => Some(@string.parse_int(node_text(sup))) catch { _ => None }
    None => None
  }
  // Notes such as `<small>bentuk tidak baku: <b>akhlas</b><b>, ihlas</b></small>`
  // follow the headword inside the same `<h2>`.
  let nonstandard_forms : Array[String] = []
  for small in @html_parser.query(h2, "small") {
    if node_text(small).to_lower().has_prefix("bentuk tidak baku") {
      for b in @html_parser.query(small, "b") {
        let form = node_text(b).trim(chars=", ").to_owned()
        if form != "" {
          nonstandard_forms.push(form)
        }
      }
    }
  }
  let headword = normalize(
    text_except(h2, ["span.rootword", "span.syllable", "sup", "small"]),
  ).replace_all(old=".", new="")
  {
    headword,
    homograph,
    pronunciation,
    root_words: roots,
    nonstandard_forms,
    senses,
  }
}

///|
fn parse_sense(li : @dom.Node) -> Sense {
  let labels : Array[Label] = []
  for span in @html_parser.query(li, "font[color=red] span[title]") {
    let code = node_text(span)
    let title = attribute(span, "title")
    let parts = title.split(":").to_array()
    let name = normalize(parts[0].to_owned())
    let description = if parts.length() > 1 {
      normalize(parts[1:].join(":"))
    } else {
      ""
    }
    labels.push({
      code,
      name: if name == "" {
        code
      } else {
        name
      },
      description,
    })
  }
  let examples : Array[Example] = []
  collect_examples(li, examples)
  let gloss = normalize(text_except(li, ["red", "grey", "brown"]))
    .trim_end(chars=":")
    .trim()
    .to_owned()
  { labels, gloss, examples, }
}

///|
fn collect_examples(node : @dom.Node, examples : Array[Example]) -> Unit {
  if node.name() == "font" {
    let color = attribute(node, "color").to_lower()
    if color == "grey" {
      for i in @html_parser.query(node, "i") {
        let value = node_text(i)
        if value != "" && value != ";" && value != "," {
          examples.push({ text: value, meaning: None, })
        }
      }
      return
    }
    if color == "brown" {
      let meaning = node_text(node)
      if meaning != "" && examples.length() > 0 {
        examples[examples.length() - 1].meaning = Some(meaning)
      }
      return
    }
  }
  for child in node.children() {
    collect_examples(child, examples)
  }
}

///|
fn list_senses(list : @dom.Node) -> Array[Sense] {
  let senses : Array[Sense] = []
  for child in list.children() {
    if child.name() == "li" {
      senses.push(parse_sense(child))
    }
  }
  senses
}

///|
/// Parses an entry page's HTML without any IO. `query` is trimmed and,
/// with `url`, copied into the result. Each `<h2>` headword followed by a
/// list of senses becomes an `Entry`; a "not found" page or HTML that cannot
/// be parsed gives `found: false`. Never raises.
pub fn parse(html : StringView, query~ : String, url~ : String) -> LookupResult {
  let trimmed = query.trim().to_owned()
  let entries : Array[Entry] = []
  let document = @html_parser.parse(html, track_node_locations=true) catch {
    _ => return { found: false, query: trimmed, url, entries, }
  }
  if !document.to_text().to_lower().contains("entri tidak ditemukan") {
    for h2 in document.query("h2") {
      match h2.parent() {
        Some(parent) => {
          let children = parent.children()
          for i in 0..<children.length() {
            if children[i].origin_offset() == h2.origin_offset() &&
              children[i].name() == "h2" {
              for j in (i + 1)..<children.length() {
                if children[j].name() == "h2" {
                  break
                }
                if children[j].name() == "ol" || children[j].name() == "ul" {
                  let senses = list_senses(children[j])
                  if senses.length() > 0 {
                    entries.push(parse_headword(h2, senses))
                    break
                  }
                }
              }
              break
            }
          }
        }
        None => ()
      }
    }
  }
  { found: entries.length() > 0, query: trimmed, url, entries, }
}
