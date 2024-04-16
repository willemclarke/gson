import gleeunit
import gleeunit/should
import gson.{JBool, JNull, JNumber, ParseError}
import gleam/string

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
