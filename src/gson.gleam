import gleam/io
import gleam/float
import gleam/int
import gleam/string
import gleam/list
import gleam/result

// https://parsed.dev/articles/Writing_your_own_JSON_parser_in_Haskell

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

  let null = parse_null(graphemes)
  let bool = parse_bool(graphemes)
  let number = parse_number(graphemes)

  null
  |> result.or(bool)
  |> result.or(number)
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
}
