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

pub type Tokens =
  List(String)

pub fn parse(input: String) -> Result(#(JValue, Tokens), String) {
  let input = string.to_graphemes(input)

  let null = parse_null(input)
  let bool = parse_bool(input)

  null
  |> result.or(bool)
}

pub fn parse_null(input: Tokens) -> Result(#(JValue, Tokens), String) {
  case input {
    [] -> Error("Not found")
    ["n", "u", "l", "l", ..input] -> Ok(#(JNull, input))
    _ -> Error("Not found")
  }
}

pub fn parse_bool(input: Tokens) -> Result(#(JValue, Tokens), String) {
  case input {
    [] -> Error("Not found")
    ["t", "r", "u", "e", ..input] -> Ok(#(JBool(True), input))
    ["f", "a", "l", "s", "e", ..input] -> Ok(#(JBool(True), input))
    _ -> Error("Not found")
  }
}

// pub fn parse_number(input: Tokens) -> Result(#(JValue, Tokens), String) {
//   case input {
//     ["-", ..input] -> Error("poop")
//   }
// }

// pub fn extract_integer(input: Tokens) -> Result(#(JValue, Tokens), String) {
//   case input {
//     ["0", ..input] -> Ok(#(JNumber(int.to_float(0)), input))
//     ["1", ..input] -> Ok(#(JNumber(int.to_float(1)), input))
//     ["2", ..input] -> Ok(#(JNumber(int.to_float(2)), input))
//     ["3", ..input] -> Ok(#(JNumber(int.to_float(3)), input))
//     ["4", ..input] -> Ok(#(JNumber(int.to_float(4)), input))
//     ["5", ..input] -> Ok(#(JNumber(int.to_float(5)), input))
//     ["6", ..input] -> Ok(#(JNumber(int.to_float(6)), input))
//     ["7", ..input] -> Ok(#(JNumber(int.to_float(7)), input))
//     ["8", ..input] -> Ok(#(JNumber(int.to_float(8)), input))
//     ["9", ..input] -> Ok(#(JNumber(int.to_float(9)), input))
//     _ -> Error("Not a valid number")
//   }
// }

// pub fn skip_whitespace(input: Tokens) -> Tokens {
//   case input {
//     [" ", ..input] -> skip_whitespace(input)
//     ["\t", ..input] -> skip_whitespace(input)
//     ["\n", ..input] -> skip_whitespace(input)
//     input -> list.drop_while(input, fn(s) { s == " " || s == "\t" })
//   }
// }

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
  let should_work = parse("null")
  let should_work_2 = parse("null")
  let should_work_3 = parse("truewith extra tokens")
  let should_work_4 = parse("123")

  // let string = render_json(JString("poop de poop"))
  // let object =
  //   render_json(
  //     JObject([
  //       #("stringKey", JString("poop1")),
  //       #("numberKey", JNumber(54.7)),
  //       #("nullKey", JNull),
  //       #("trueKey", JBool(True)),
  //       #("falseKey", JBool(False)),
  //     ]),
  //   )

  // let array =
  //   render_json(
  //     JArray([
  //       JString("I'm a string"),
  //       JObject([#("key1", JString("poop1")), #("key2", JNumber(54.7))]),
  //     ]),
  //   )

  io.debug(should_work)
  io.debug(should_work_2)
  io.debug(should_work_3)
  io.debug(should_work_4)
}
