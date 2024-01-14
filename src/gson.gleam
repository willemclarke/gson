import gleam/io
import gleam/float
import gleam/string
import gleam/list
import gleam/pair

pub type JValue {
  JString(value: String)
  JNumber(value: Float)
  JBool(value: Bool)
  JNull
  JObject(value: List(#(String, JValue)))
  JArray(value: List(JValue))
}

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
        "{" <> key <> ": " <> render_json(value) <> "}"
      }

      let pairs =
        list.map(object, fn(pair) {
          let key = pair.first(pair)
          let value = pair.second(pair)
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
  let string = render_json(JString(value: "poop de poop"))
  let object =
    render_json(
      JObject(value: [
        #("stringKey", JString(value: "poop1")),
        #("numberKey", JNumber(value: 54.7)),
        #("nullKey", JNull),
        #("trueKey", JBool(value: True)),
        #("falseKey", JBool(value: False)),
      ]),
    )
  let array =
    render_json(
      JArray([
        JString(value: "I'm a string"),
        JObject(value: [
          #("key1", JString(value: "poop1")),
          #("key2", JNumber(value: 54.7)),
        ]),
      ]),
    )
  io.debug(string)
  io.debug(object)
  io.debug(array)
}
