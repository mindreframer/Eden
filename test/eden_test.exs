defmodule EdenTest do
  use ExUnit.Case
  import Eden
  alias Eden.Character
  alias Eden.Symbol
  alias Eden.UUID
  alias Eden.Tag
  alias Eden.Exception, as: Ex

  ## Decode

  describe "decode" do
    test "empty" do
      e = %Ex.EmptyInputError{}
      assert decode("") == {:error, e.__struct__}

      assert_raise Ex.EmptyInputError, fn ->
        decode!("")
      end
    end

    test "literals" do
      assert decode!("nil") == nil
      assert decode!("true") == true
      assert decode!("false") == false
      assert decode!("false false") == [false, false]

      assert decode!("\"hello world!\"") == "hello world!"
      assert decode!("\"hello \\n world!\"") == "hello \n world!"

      assert decode!("\\n") == %Character{char: "n"}
      assert decode!("\\z") == %Character{char: "z"}

      assert decode!("a-symbol") == %Symbol{name: "a-symbol"}
      assert decode!(":the-keyword") == :"the-keyword"

      assert decode!("42") == 42
      assert decode!("42N") == 42

      assert decode!("42.0") == 42.0
      assert decode!("42M") == 42.0
      assert decode!("42.0e3") == 42000.0
      assert decode!("42e-3") == 0.042
      assert decode!("42E-1") == 4.2
      assert decode!("42.01E+1") == 420.1
    end

    test "list" do
      assert decode!("(1 :a 42.0)") == [1, :a, 42.0]
    end

    test "vector" do
      array = Array.from_list([1, :a, 42.0])
      assert decode!("[1 :a 42.0]") == array
    end

    test "map" do
      map = %{name: "John", age: 42}
      assert decode!("{:name \"John\" :age 42}") == map

      assert_raise Ex.OddExpressionCountError, fn ->
        decode!("{:name \"John\" :age}")
      end
    end

    test "set" do
      set = Enum.into([:name, "John", :age, 42], MapSet.new())
      assert decode!("#\{:name \"John\" :age 42}") == set
    end

    test "tag" do
      date = parse_datetime("1985-04-12T23:20:50.52Z")
      assert decode!("#inst \"1985-04-12T23:20:50.52Z\"") == date

      assert decode!("#uuid \"f81d4fae-7dec-11d0-a765-00a0c91e6bf6\"") == %UUID{
               value: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
             }

      assert decode!(~s{#date "2019-12-31"}) == ~D[2019-12-31]
      assert decode!("#custom/tag (1 2 3)") == %Tag{name: "custom/tag", value: [1, 2, 3]}
      handlers = %{"custom/tag" => &custom_tag_handler/1}
      assert decode!("#custom/tag (1 2 3)", handlers: handlers) == [:a, :b, :c]
    end

    defmodule StructDec1 do
      defstruct a: "", b: 0
    end

    defmodule StructDec2 do
      defstruct nested: []

      def new() do
        %StructDec2{nested: [%StructDec1{a: "1"}, %StructDec1{a: "2"}]}
      end
    end

    test "struct - with preserve_structs: true" do
      res = StructDec2.new() |> encode!(preserve_structs: true) |> decode!(preserve_structs: true)
      assert res == StructDec2.new()
    end

    test "struct - with preserve_structs: false" do
      res = StructDec2.new() |> encode!(preserve_structs: false) |> decode!(preserve_structs: false)
      assert res == %{nested: [%{a: "1", b: 0}, %{a: "2", b: 0}]}
    end
  end

  describe "encode" do
    test "literals" do
      assert encode!(nil) == "nil"
      assert encode!(true) == "true"
      assert encode!(false) == "false"

      assert encode!("hello world!") == "\"hello world!\""
      assert encode!("hello \n world!") == "\"hello \n world!\""

      assert encode!(Character.new("n")) == "\\n"
      assert encode!(Character.new("z")) == "\\z"

      assert encode!(Symbol.new("a-symbol")) == "a-symbol"
      assert encode!(:"the-keyword") == ":the-keyword"

      assert encode!(42) == "42"

      assert encode!(42.0) == "42.0"
      assert encode!(42.0e3) == "4.2e4"
      assert encode!(42.0e-3) == "0.042"
      assert encode!(42.0e-1) == "4.2"
      assert encode!(42.01e+1) == "420.1"
    end

    test "list" do
      assert encode!([1, :a, 42.0]) == "(1, :a, 42.0)"
    end

    test "vector" do
      array = Array.from_list([1, :a, 42.0])
      assert encode!(array) == "[1, :a, 42.0]"
    end

    test "map" do
      map = %{name: "John", age: 42}
      assert encode!(map) == "{:age 42, :name \"John\"}"
    end

    test "set" do
      set = Enum.into([:name, "John", :age, 42], MapSet.new())
      assert encode!(set) == "\#{42, :age, :name, \"John\"}"
    end

    test "tag" do
      date = parse_datetime("1985-04-12T23:20:50.52Z")
      assert encode!(date) == "#inst \"1985-04-12T23:20:50.52Z\""
      uuid = UUID.new("f81d4fae-7dec-11d0-a765-00a0c91e6bf6")
      assert encode!(uuid) == "#uuid \"f81d4fae-7dec-11d0-a765-00a0c91e6bf6\""

      date = ~D[2019-12-31]
      assert encode!(date) == "#date \"2019-12-31\""

      some_tag = Tag.new("custom/tag", :joni)
      assert encode!(some_tag) == "#custom/tag :joni"
    end

    defmodule StructEnc1 do
      defstruct a: "", b: 0
    end

    defmodule StructEnc2 do
      defstruct nested: []

      def new() do
        %StructEnc2{nested: [%StructEnc1{a: "1"}, %StructEnc1{a: "2"}]}
      end
    end

    test "struct" do
      preserved =
        "#Elixir.EdenTest.StructEnc2 {:nested (#Elixir.EdenTest.StructEnc1 {:a \"1\", :b 0}, #Elixir.EdenTest.StructEnc1 {:a \"2\", :b 0})}"

      plain = "{:nested ({:a \"1\", :b 0}, {:a \"2\", :b 0})}"
      assert encode!(StructEnc2.new(), preserve_structs: true) == preserved
      assert encode!(StructEnc2.new(), preserve_structs: false) == plain
    end

    test "fallback to Any" do
      node = %Eden.Parser.Node{}
      map = Map.from_struct(node)
      assert encode!(node) == encode!(map)
    end

    test "unknown type" do
      e = %Protocol.UndefinedError{}
      assert encode(self()) == {:error, e.__struct__}

      assert_raise Protocol.UndefinedError, fn ->
        encode!(self())
      end

      try do
        encode!(self())
      rescue
        e in Protocol.UndefinedError ->
          assert e.protocol == Eden.Encode
          assert e.value == self()
      end
    end
  end

  defp custom_tag_handler(value) when is_list(value) do
    mapping = %{1 => :a, 2 => :b, 3 => :c}
    Enum.map(value, fn x -> mapping[x] end)
  end

  defp parse_datetime(datetime) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime)
    datetime
  end
end
