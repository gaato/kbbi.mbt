///|
pub const DEFAULT_BASE_URL : String = "https://kbbi.kemendikdasmen.go.id"

///|
pub struct LookupResult {
  found : Bool
  query : String
  url : String
  entries : Array[Entry]
} derive(ToJson, Debug, Eq)

///|
pub struct Entry {
  headword : String
  homograph : Int?
  pronunciation : String?
  root_words : Array[String]
  senses : Array[Sense]
} derive(ToJson, Debug, Eq)

///|
pub struct Sense {
  labels : Array[Label]
  gloss : String
  examples : Array[Example]
} derive(ToJson, Debug, Eq)

///|
pub struct Label {
  code : String
  name : String
  description : String
} derive(ToJson, Debug, Eq)

///|
pub struct Example {
  text : String
  mut meaning : String?
} derive(ToJson, Debug, Eq)

///|
pub suberror KbbiError {
  EmptyQuery
  Http(@http.HttpError)
  Status(Int)
  Decode(String)
} derive(Debug)

///|
pub extend LookupResult with ToJson::{to_json}

///|
pub extend LookupResult with Debug::{to_repr}

///|
pub extend LookupResult with Eq::{equal, not_equal}

///|
pub extend Entry with ToJson::{to_json}

///|
pub extend Entry with Debug::{to_repr}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Sense with ToJson::{to_json}

///|
pub extend Sense with Debug::{to_repr}

///|
pub extend Sense with Eq::{equal, not_equal}

///|
pub extend Label with ToJson::{to_json}

///|
pub extend Label with Debug::{to_repr}

///|
pub extend Label with Eq::{equal, not_equal}

///|
pub extend Example with ToJson::{to_json}

///|
pub extend Example with Debug::{to_repr}

///|
pub extend Example with Eq::{equal, not_equal}

///|
pub extend KbbiError with Debug::{to_repr}
