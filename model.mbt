///|
/// The KBBI Daring site that `lookup` and `entry_url` use unless a
/// `base_url` is given.
pub const DEFAULT_BASE_URL : String = "https://kbbi.kemendikdasmen.go.id"

///|
/// The outcome of one lookup. `found` is true when `entries` is not empty;
/// `query` is the trimmed query and `url` the entry page that was read.
pub struct LookupResult {
  found : Bool
  query : String
  url : String
  entries : Array[Entry]
} derive(ToJson, Debug, Eq)

///|
/// One headword on an entry page, with its senses in page order.
///
/// `headword` has KBBI's syllable dots removed; `homograph` is the
/// superscript number that tells homographs apart, and `pronunciation` the
/// syllable spelling KBBI gives for some words. `root_words` lists the words
/// a derived form is built from.
pub struct Entry {
  headword : String
  homograph : Int32?
  pronunciation : String?
  root_words : Array[String]
  /// Nonstandard spellings from the heading's "bentuk tidak baku" note.
  nonstandard_forms : Array[String]
  senses : Array[Sense]
} derive(ToJson, Debug, Eq)

///|
/// One numbered definition of an entry: its word-class and usage labels,
/// the definition text in `gloss`, and the example phrases that follow it.
pub struct Sense {
  labels : Array[Label]
  gloss : String
  examples : Array[Example]
} derive(ToJson, Debug, Eq)

///|
/// A word-class or usage label on a sense, such as `v` for a verb.
///
/// `code` is the abbreviation shown on the page, `name` the label's full
/// name (the code when KBBI gives none), and `description` the explanation
/// after the name, or empty when there is none.
pub struct Label {
  code : String
  name : String
  description : String
} derive(ToJson, Debug, Eq)

///|
/// An example phrase for a sense. In `text`, `--` stands for the headword;
/// `meaning` holds the explanation KBBI gives for an idiomatic example.
pub struct Example {
  text : String
  mut meaning : String?
} derive(ToJson, Debug, Eq)

///|
/// Why `lookup` failed: the query was empty after trimming, the transport
/// failed, the site answered with a non-2xx status, or the body was not
/// valid UTF-8.
pub suberror KbbiError {
  EmptyQuery
  Http(@http.HttpError)
  Status(Int32)
  Decode(String)
} derive(Debug)

///|
/// Converts a `LookupResult` to JSON with the derived `ToJson`.
pub extend LookupResult with ToJson::{to_json}

///|
/// Renders a `LookupResult` for debugging with the derived `Debug`.
pub extend LookupResult with Debug::{to_repr}

///|
/// Compares two `LookupResult` values field by field with the derived `Eq`.
pub extend LookupResult with Eq::{equal, not_equal}

///|
/// Converts a `Entry` to JSON with the derived `ToJson`.
pub extend Entry with ToJson::{to_json}

///|
/// Renders a `Entry` for debugging with the derived `Debug`.
pub extend Entry with Debug::{to_repr}

///|
/// Compares two `Entry` values field by field with the derived `Eq`.
pub extend Entry with Eq::{equal, not_equal}

///|
/// Converts a `Sense` to JSON with the derived `ToJson`.
pub extend Sense with ToJson::{to_json}

///|
/// Renders a `Sense` for debugging with the derived `Debug`.
pub extend Sense with Debug::{to_repr}

///|
/// Compares two `Sense` values field by field with the derived `Eq`.
pub extend Sense with Eq::{equal, not_equal}

///|
/// Converts a `Label` to JSON with the derived `ToJson`.
pub extend Label with ToJson::{to_json}

///|
/// Renders a `Label` for debugging with the derived `Debug`.
pub extend Label with Debug::{to_repr}

///|
/// Compares two `Label` values field by field with the derived `Eq`.
pub extend Label with Eq::{equal, not_equal}

///|
/// Converts a `Example` to JSON with the derived `ToJson`.
pub extend Example with ToJson::{to_json}

///|
/// Renders a `Example` for debugging with the derived `Debug`.
pub extend Example with Debug::{to_repr}

///|
/// Compares two `Example` values field by field with the derived `Eq`.
pub extend Example with Eq::{equal, not_equal}

///|
/// Renders a `KbbiError` for debugging with the derived `Debug`.
pub extend KbbiError with Debug::{to_repr}
