defmodule Eden.FormatterTest do
  use ExUnit.Case
  alias Eden.Formatter
  defmodule Person, do: defstruct(age: 0, name: nil)

  test "list" do
    check([1, 2, 3], "(\n  1,\n  2,\n  3\n)")
  end

  test "map - atom keys" do
    check(%{a: 1, b: 2}, "{\n  :a 1,\n  :b 2\n}")
  end

  test "map - string keys" do
    check(%{"a" => 1}, "{\n  \"a\" 1\n}")
  end

  test "map - string keys, that include commas in values" do
    check(%{"a" => "Come on, dude!"}, "{\n  \"a\" \"Come on, dude!\"\n}")
  end

  test "MapSet" do
    check(MapSet.new([1, 2]), "\#{\n  1,\n  2\n}")
  end

  test "Struct" do
    check(
      %Person{age: 7, name: "name"},
      "#Elixir.Eden.FormatterTest.Person {\n  :age 7,\n  :name \"name\"\n}"
    )
  end

  def check(input, expect) do
    enc = Eden.encode!(input, preserve_structs: true)
    pretty = Formatter.pretty_print(enc)
    dec = Eden.decode!(pretty, preserve_structs: true)

    assert pretty == expect
    assert input == dec
  end
end
