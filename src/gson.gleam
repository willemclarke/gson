import gleam/io
import gleam/float
import gleam/string
import gleam/list.{Continue, Stop}
import gleam/option
import gleam/result

// https://parsed.dev/articles/Writing_your_own_JSON_parser_in_Haskell

// --- parser ---

pub type JValue {
  JString(String)
  JNumber(Float)
  JBool(Bool)
  JNull
  JObject(List(#(String, JValue)))
  JArray(List(JValue))
}

pub fn parse_json(input: String) -> Result(#(JValue, String), String) {
  let null = option.to_result(parse_null(input), "Unable to parse null")
  let bool = option.to_result(parse_bool(input), "Unable to parse bool")

  null
  |> result.or(bool)
}

// TODO: make parse_null & parse_bool return results
pub fn parse_null(input: String) -> option.Option(#(JValue, String)) {
  case input {
    "null" -> {
      let next_string = string.drop_left(from: input, up_to: 4)
      option.Some(#(JNull, next_string))
    }
    _ -> option.None
  }
}

pub fn parse_bool(input: String) -> option.Option(#(JValue, String)) {
  case input {
    "true" -> {
      let next_string = string.drop_left(from: input, up_to: 4)
      option.Some(#(JBool(True), next_string))
    }
    "false" -> {
      let next_string = string.drop_left(from: input, up_to: 5)
      option.Some(#(JBool(False), next_string))
    }
    _ -> option.None
  }
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
  let should_work = parse_json("nul")
  let should_work_2 = parse_json("nul")
  let should_work_3 = parse_json("true")
  let should_work_4 = parse_json("false")

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
