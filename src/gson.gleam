import gleam/io
import gleam/float
import gleam/int
import gleam/string
import gleam/list
import gleam/result

// https://parsed.dev/articles/Writing_your_own_JSON_parser_in_Haskell

// --- Parser ----

pub type JValue {
  JString(String)
  JNumber(Float)
  JBool(Bool)
  JNull
  JObject(List(#(String, JValue)))
  JArray(List(JValue))
}

pub type ParseError {
  ParseError(expected: String, got: String)
}

pub type Tokens =
  List(String)

pub fn parse(input: String) -> Result(#(JValue, Tokens), ParseError) {
  let graphemes = string.to_graphemes(input)
  let without_whitespace = skip_whitespace(graphemes)

  parse_json(without_whitespace)
}

pub fn parse_json(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  let try_null = parse_null(input)
  let try_bool = parse_bool(input)
  let try_number = parse_number(input)
  let try_string = parse_string(input)
  let try_array = parse_array(input)

  try_null
  |> result.or(try_bool)
  |> result.or(try_number)
  |> result.or(try_string)
  |> result.or(try_array)
}

pub fn parse_null(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  case input {
    ["n", "u", "l", "l", ..input] -> Ok(#(JNull, input))
    _ -> Error(ParseError(expected: "null", got: got_to_string(input)))
  }
}

pub fn parse_bool(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  case input {
    ["t", "r", "u", "e", ..input] -> Ok(#(JBool(True), input))
    ["f", "a", "l", "s", "e", ..input] -> Ok(#(JBool(False), input))
    _ -> Error(ParseError(expected: "true/false", got: got_to_string(input)))
  }
}

pub fn parse_string(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  case input {
    ["\"", ..rest] -> {
      let #(string, remaining) = parse_string_inner(rest)
      Ok(#(JString(string), remaining))
    }
    _ -> Error(ParseError(expected: "\"", got: get_firt_token(input)))
  }
}

fn parse_string_inner(input: Tokens) -> #(String, Tokens) {
  case input {
    [] -> #("", [])

    ["\"", ..rest] -> #("", rest)

    ["\\", char, ..rest] -> {
      let #(first, remaining) = parse_string_inner(rest)
      let escaped = escape_character(char)

      #(escaped <> first, remaining)
    }

    [char, ..rest] -> {
      let #(first, remaining) = parse_string_inner(rest)
      #(char <> first, remaining)
    }
  }
}

pub fn parse_number(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  case input {
    ["-", ..] -> {
      parse_double(input)
      |> result.try(fn(res) {
        let #(float, rest) = res
        Ok(#(JNumber(float), rest))
      })
    }
    [x, ..] -> {
      case is_digit(x) {
        True -> {
          parse_double(input)
          |> result.try(fn(res) {
            let #(float, rest) = res
            Ok(#(JNumber(float), rest))
          })
        }
        False -> Error(ParseError(expected: "digit", got: x))
      }
    }
    _ -> Error(ParseError(expected: "digit or -", got: get_firt_token(input)))
  }
}

pub fn parse_double(input: Tokens) -> Result(#(Float, Tokens), ParseError) {
  let #(whole_integer, remaining) = extract_integer(input)

  case remaining {
    ["-", ..xs] -> {
      parse_double(xs)
      |> result.map(fn(pair) {
        let #(num, rest) = pair
        #(float.negate(num), rest)
      })
    }
    [".", ..xs] -> {
      let #(fractional_part, rest) = extract_integer(xs)

      let whole_as_string = string.join(whole_integer, "")
      let fractional_as_string = string.join(fractional_part, "")
      let to_float = whole_as_string <> "." <> fractional_as_string

      case float.parse(to_float) {
        Ok(float) -> Ok(#(float, rest))
        Error(_) -> Error(ParseError(expected: "valid float", got: to_float))
      }
    }
    _ -> {
      whole_integer
      |> string.join("")
      |> int.parse()
      |> result.try(fn(number) {
        let float = int.to_float(number)
        Ok(#(float, remaining))
      })
      |> result.map_error(fn(_) {
        ParseError(expected: "valid integer", got: got_to_string(whole_integer))
      })
    }
  }
}

pub fn extract_integer(input: Tokens) -> #(Tokens, Tokens) {
  case input {
    [] -> #([], [])

    [x, ..xs] -> {
      case is_digit(x) {
        True -> {
          let #(nums, rest) = extract_integer(xs)
          let appended = [x, ..nums]

          #(appended, rest)
        }
        False -> #([], [x, ..xs])
      }
    }
  }
}

pub fn parse_array(input: Tokens) -> Result(#(JValue, Tokens), ParseError) {
  case input {
    ["[", "]"] -> Ok(#(JArray([]), []))

    ["[", ..rest] -> {
      parse_array_inner(skip_whitespace(rest))
      |> result.map(fn(tuple) {
        let #(list_items, remaining) = tuple
        #(JArray(list_items), remaining)
      })
    }

    _ -> Error(ParseError(expected: "[/]", got: get_firt_token(input)))
  }
}

fn parse_array_inner(
  input: Tokens,
) -> Result(#(List(JValue), Tokens), ParseError) {
  let parsed = parse_json(skip_whitespace(input))

  case parsed {
    Ok(#(jvalue, following)) -> {
      case following {
        [",", ..rest] -> {
          parse_array_inner(skip_whitespace(rest))
          |> result.map(fn(tuple) {
            let #(first, remaining) = tuple
            #([jvalue, ..first], remaining)
          })
        }

        ["]", ..rest] -> Ok(#([jvalue], rest))

        _ -> Ok(#([JArray([])], []))
      }
    }
    Error(_) -> Error(ParseError(expected: "]", got: get_firt_token(input)))
  }
}

// --- helper methods ---

fn skip_whitespace(input: Tokens) -> Tokens {
  case input {
    [] -> []
    ["[", "]", ..rest] -> skip_whitespace(rest)
    [" ", ..rest] -> skip_whitespace(rest)
    ["\n", ..rest] -> skip_whitespace(rest)
    ["\r", ..rest] -> skip_whitespace(rest)
    ["\t", ..rest] -> skip_whitespace(rest)
    [char, ..rest] -> [char, ..skip_whitespace(rest)]
  }
}

fn escape_character(char: String) -> String {
  case char {
    "\"" -> "\""
    "\\" -> "\\"
    "/" -> "/"
    "b" -> "\u{8}"
    "f" -> "\f"
    "r" -> "\r"
    "n" -> "\n"
    _ -> char
  }
}

pub fn is_digit(input: String) -> Bool {
  case input {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn got_to_string(got: Tokens) -> String {
  string.join(got, "")
}

fn get_firt_token(tokens: Tokens) -> String {
  tokens
  |> list.first()
  |> result.unwrap("")
}

// --- render thing ----

pub fn render_json(jvalue: JValue) -> String {
  case jvalue {
    JString(str) -> str
    JNumber(float) -> float.to_string(float)
    JNull -> "true"
    JBool(bool) -> {
      case bool {
        True -> "true"
        False -> "false"
      }
    }
    JObject(object) -> {
      let render_pair = fn(key: String, value: JValue) -> String {
        "{ " <> key <> ": " <> render_json(value) <> " }"
      }

      let pairs =
        list.map(object, fn(pair) {
          let #(key, value) = pair
          render_pair(key, value)
        })

      string.join(pairs, ", ")
    }
    JArray(array) -> {
      let values =
        list.map(array, render_json)
        |> string.join(", ")

      "[" <> values <> "]"
    }
  }
}

pub fn main() {
  io.debug(parse("null"))
  io.debug(parse("truewith extra tokens"))
  io.debug(parse("12"))
  io.debug(parse("1234cat"))
  io.debug(parse("-1234"))
  io.debug(parse("1.5wa"))
  io.debug(parse("15.36wa"))
  io.debug(parse("-12.34"))
  io.debug(parse("\"hello world\""))
}
