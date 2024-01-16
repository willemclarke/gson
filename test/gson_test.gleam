import gleeunit
import gleeunit/should
import gson
import gleam/option

pub fn main() {
  gleeunit.main()
}

pub fn parse_null_test() {
  gson.parse_null("null")
  |> should.equal(option.Some(#(gson.JNull, "")))

  gson.parse_null("nul")
  |> should.equal(option.None)
}

pub fn parse_bool_test() {
  gson.parse_bool("true")
  |> should.equal(option.Some(#(gson.JBool(True), "")))

  gson.parse_bool("false")
  |> should.equal(option.Some(#(gson.JBool(False), "")))

  gson.parse_bool("tru")
  |> should.equal(option.None)
}
