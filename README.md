Eden
=====

[![Travis](https://img.shields.io/travis/jfacorro/Eden.svg?style=flat-square)](https://travis-ci.org/jfacorro/Eden)
[![Hex.pm](https://img.shields.io/hexpm/v/eden.svg?style=flat-square)](https://hex.pm/packages/eden)
[![Hex.pm](https://img.shields.io/hexpm/dt/eden.svg?style=flat-square)](https://hex.pm/packages/eden)

[edn](https://github.com/edn-format/edn) (extensible data notation) encoder/decoder implemented in Elixir.

## Usage

Include Eden as a dependency in your Elixir project by adding it in your `deps` list:

```elixir
def deps do
  [{:eden, "~> 0.1.2"}]
end
```

Eden is a library application and as such doesn't specify an application callback module. Even so, if you would like to build a release that includes Eden, you need to add it as an application dependency in your `mix.exs`:

```elixir
  def application do
    [applications: [:eden]]
  end
```

## Examples

```elixir
iex> Eden.encode([1, 2])
{:ok, "(1, 2)"}

iex> Eden.encode(%{a: 1, b: 2, c: 3})
{:ok, "{:a 1, :b 2, :c 3}"}

iex> Eden.encode({:a, 1})
{:error, Protocol.UndefinedError}

# can work transparently with Elixir structs (without tuple-values)
iex> defmodule User, do: defstruct name: nil, age: nil

iex> %User{age: 20, name: "Name"} |> Eden.encode!(preserve_structs: true) |> IO.inspect() |> Eden.decode!(preserve_structs: true)
"#Elixir.User {:age 20, :name \"Name\"}"
%User{age: 20, name: "Name"}

iex> Eden.decode("{:a 1 :b 2}")
{:ok, %{a: 1, b: 2}}

iex> Eden.decode("(hello :world \\!)")
{:ok, [%Eden.Symbol{name: "hello"}, :world, %Eden.Character{char: "!"}]

iex> Eden.decode("[1 2 3 4]")
{:ok, #Array<[1, 2, 3, 4], fixed=false, default=nil>}

iex> Eden.decode("nil true false")
{:ok, [nil, true, false]}

iex> Eden.decode("nil true false .")
{:error, Eden.Exception.UnexpectedInputError}
```

## Data Structures Mapping: **edn** <-> **Elixir**

|  Edn | Elixir   |
|---|---|
| `nil`      | `:nil = nil` |
| `true`   | `:true = true` |
| `false`  | `:false = false` |
| `string` | `String` |
| `character` | `Eden.Character` |
| `symbol`  | `Eden.Symbol` |
| `keyword`  | `Atom` |
| `integer`  | `Integer` |
| `float`  | `Float` |
| `list`  | `List`  |
| `vector`  | `Array`  |
| `map`  | `Map` |
| `set`  | `MapSet` |
| `#inst`  | `Elixir.DateTime` |
| `#uuid`  | `Eden.UUID` |
| `#date`  | `Elixir.Date` |

## Further Considerations

### `Character`

There is no way of distinguishing a common integer from the representation of a character in a `String` or in `Char lists`. This forces the creation of a new representation for this type so it can be correctly translated from and to **edn**.

### Arbitrary Precision `Integer` and `Float`

The Erlang VM (EVM) only provides arbitrary precision integers so all integers will be of this type this and the `N` modifier will be ignored when parsing an **edn** integer.

On the other hand native arbitrary precision floating point numbers are not provided by the EVM so all values of type `float` will be represented according to what the EVM supports.

### `Keyword` and `Symbol` Representation

On one hand the decision to translate **edn** `keyword`s as Elixir `atom`s comes from the fact these two data types are given a similar usage on both languages. On the other, it might get awkward really fast using a new `Eden.Symbol` struct as the representation for **edn**'s `symbol`s so this might change.

### `vector`

There is no constant lookup or nearly constant indexed data structure like **edn**'s `vector` other than the `:array` data structure implemented in one of Erlang's standard library modules. Until there is a better implementation for this `Eden` will use [`Array`](https://github.com/takscape/elixir-array), an Elixir wrapper library for Erlang's array.

### Elixir structs

To enable transparent encoding / decoding for your Elixir structs, pass the option: `preserve_structs: true` to both `Eden.encode` / `Eden.decode` functions.

## **edn** grammar

```
expr -> literal | map | list | vector | tagged_value

literal -> nil | true | false | keyword | symbol | integer | float | string

map -> { pair* }
pair -> expr expr

list -> ( expr* )

vector -> [ expr* ]

tagged_value -> tag expr

```
