import gleeunit
import gleeunit/should
import gson.{JArray, JBool, JNull, JNumber, JObect, JString, ParseError}
import gleam/string
import gleam/dict

pub fn main() {
  gleeunit.main()
}

pub fn null_test() {
  // valid cases
  string.split("null", "")
  |> gson.parse_null()
  |> should.equal(Ok(#(JNull, [])))

  string.split("nullhello", "")
  |> gson.parse_null()
  |> should.equal(Ok(#(JNull, ["h", "e", "l", "l", "o"])))

  // error case
  string.split("invalid", "")
  |> gson.parse_null()
  |> should.equal(Error(ParseError(expected: "null", got: "invalid")))
}

pub fn bool_test() {
  // valid cases
  string.split("true", "")
  |> gson.parse_bool()
  |> should.equal(Ok(#(JBool(True), [])))

  string.split("trueabc123", "")
  |> gson.parse_bool()
  |> should.equal(Ok(#(JBool(True), ["a", "b", "c", "1", "2", "3"])))

  string.split("trueabc 123", "")
  |> gson.parse_bool()
  |> should.equal(Ok(#(JBool(True), ["a", "b", "c", " ", "1", "2", "3"])))

  string.split("false", "")
  |> gson.parse_bool()
  |> should.equal(Ok(#(JBool(False), [])))

  string.split("falseabc", "")
  |> gson.parse_bool()
  |> should.equal(Ok(#(JBool(False), ["a", "b", "c"])))

  // error case
  string.split("steelseries", "")
  |> gson.parse_bool()
  |> should.equal(Error(ParseError(expected: "true/false", got: "steelseries")))
}

pub fn number_test() {
  // valid cases
  string.split("12", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(12.0), [])))

  string.split("-12", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(-12.0), [])))

  string.split("15.36", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(15.36), [])))

  string.split("-15.36", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(-15.36), [])))

  string.split("-15.36abc", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(-15.36), ["a", "b", "c"])))

  string.split("-1690.7656", "")
  |> gson.parse_number()
  |> should.equal(Ok(#(JNumber(-1690.7656), [])))

  // error case
  string.split("invalid", "")
  |> gson.parse_number()
  |> should.equal(Error(ParseError(expected: "digit", got: "i")))
}

pub fn string_test() {
  // valid cases
  string.split("\"hello\"", "")
  |> gson.parse_string()
  |> should.equal(Ok(#(JString("hello"), [])))

  string.split("\"Hello world \r\n\\QQQ 523\"", "")
  |> gson.parse_string()
  |> should.equal(Ok(#(JString("Hello world \r\nQQQ 523"), [])))

  string.split("\"HELLO MAN 12323 25 SIXTY\"", "")
  |> gson.parse_string()
  |> should.equal(Ok(#(JString("HELLO MAN 12323 25 SIXTY"), [])))

  // error case
  string.split("2", "")
  |> gson.parse_string()
  |> should.equal(Error(ParseError(expected: "\"", got: "2")))

  string.split("hello", "")
  |> gson.parse_string()
  |> should.equal(Error(ParseError(expected: "\"", got: "h")))
}

pub fn array_test() {
  // valid cases
  string.split("[]", "")
  |> gson.parse_array()
  |> should.equal(Ok(#(JArray([]), [])))

  string.split("[null]", "")
  |> gson.parse_array()
  |> should.equal(Ok(#(JArray([JNull]), [])))

  string.split("[true]", "")
  |> gson.parse_array()
  |> should.equal(Ok(#(JArray([JBool(True)]), [])))

  string.split("[false]", "")
  |> gson.parse_array()
  |> should.equal(Ok(#(JArray([JBool(False)]), [])))

  string.split("[1,2,3,4]", "")
  |> gson.parse_array()
  |> should.equal(
    Ok(#(JArray([JNumber(1.0), JNumber(2.0), JNumber(3.0), JNumber(4.0)]), [])),
  )

  string.split("[1,2,[3,4]]", "")
  |> gson.parse_array()
  |> should.equal(
    Ok(
      #(
        JArray([
          JNumber(1.0),
          JNumber(2.0),
          JArray([JNumber(3.0), JNumber(4.0)]),
        ]),
        [],
      ),
    ),
  )

  // error case
  string.split("", "")
  |> gson.parse_array()
  |> should.equal(Error(ParseError("[/]", "")))

  string.split("{}", "")
  |> gson.parse_array()
  |> should.equal(Error(ParseError("[/]", "{")))

  string.split("[", "")
  |> gson.parse_array()
  |> should.equal(Error(ParseError("]", "")))
}

pub fn parse_test() {
  // null
  gson.parse("null")
  |> should.equal(Ok(#(JNull, [])))

  // booleans
  gson.parse("true")
  |> should.equal(Ok(#(JBool(True), [])))

  gson.parse("false")
  |> should.equal(Ok(#(JBool(False), [])))

  // strings
  gson.parse("\"1234\"")
  |> should.equal(Ok(#(JString("1234"), [])))

  gson.parse("\"1234cat      \"")
  |> should.equal(Ok(#(JString("1234cat"), [])))

  // numbers
  gson.parse("123")
  |> should.equal(Ok(#(JNumber(123.0), [])))

  gson.parse("-54.37   ")
  |> should.equal(Ok(#(JNumber(-54.37), [])))

  // arrays
  gson.parse("[1,2,3,4]   ")
  |> should.equal(
    Ok(#(JArray([JNumber(1.0), JNumber(2.0), JNumber(3.0), JNumber(4.0)]), [])),
  )

  gson.parse("[true] 123")
  |> should.equal(Ok(#(JArray([JBool(True)]), ["1", "2", "3"])))

  gson.parse("[1,2,[3,4]]")
  |> should.equal(
    Ok(
      #(
        JArray([
          JNumber(1.0),
          JNumber(2.0),
          JArray([JNumber(3.0), JNumber(4.0)]),
        ]),
        [],
      ),
    ),
  )

  gson.parse("{\"items\": [1,2,3]}")
  |> should.equal(
    Ok(
      #(
        JObect(
          dict.from_list([
            #("items", JArray([JNumber(1.0), JNumber(2.0), JNumber(3.0)])),
          ]),
        ),
        [],
      ),
    ),
  )

  gson.parse(
    "{\"items\":[1,2,   \"This is a mixed array\",4],\"bob\":false,\"cat\":\"Hello I am a cat\"}",
  )
  |> should.equal(
    Ok(
      #(
        JObect(
          dict.from_list([
            #("bob", JBool(False)),
            #("cat", JString("HelloIamacat")),
            #(
              "items",
              JArray([
                JNumber(1.0),
                JNumber(2.0),
                JString("Thisisamixedarray"),
                JNumber(4.0),
              ]),
            ),
          ]),
        ),
        [],
      ),
    ),
  )
}
