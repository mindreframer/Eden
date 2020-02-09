alias Eden.Encode
alias Eden.Encode.Utils
alias Eden.Character
alias Eden.Symbol
alias Eden.UUID
alias Eden.Tag

defprotocol Eden.Encode do
  @fallback_to_any true

  @spec encode(any) :: String.t()
  def encode(value, _opts \\ [])
end

defmodule Eden.Encode.Utils do
  def wrap(str, first, last) do
    first <> str <> last
  end
end

defimpl Encode, for: Atom do
  def encode(atom, _opts) when atom in [nil, true, false] do
    Atom.to_string(atom)
  end

  def encode(atom, _opts) do
    ":" <> Atom.to_string(atom)
  end
end

defimpl Encode, for: Symbol do
  def encode(symbol, _opts) do
    symbol.name
  end
end

defimpl Encode, for: BitString do
  def encode(string, _opts) do
    "\"#{string}\""
  end
end

defimpl Encode, for: Character do
  def encode(char, _opts) do
    "\\#{char.char}"
  end
end

defimpl Encode, for: Integer do
  def encode(int, _opts) do
    "#{inspect(int)}"
  end
end

defimpl Encode, for: Float do
  def encode(float, _opts) do
    "#{inspect(float)}"
  end
end

defimpl Encode, for: List do
  def encode(list, opts) do
    list
    |> Enum.map(fn x -> Encode.encode(x, opts) end)
    |> Enum.join(", ")
    |> Utils.wrap("(", ")")
  end
end

defimpl Encode, for: Array do
  def encode(array, opts) do
    array
    |> Array.to_list()
    |> Enum.map(fn x -> Encode.encode(x, opts) end)
    |> Enum.join(", ")
    |> Utils.wrap("[", "]")
  end
end

defimpl Encode, for: Map do
  def encode(map, opts) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> Encode.encode(k, opts) <> " " <> Encode.encode(v, opts) end)
    |> Enum.join(", ")
    |> Utils.wrap("{", "}")
  end
end

defimpl Encode, for: MapSet do
  def encode(set, _opts) do
    set
    |> Enum.map(&Encode.encode/1)
    |> Enum.join(", ")
    |> Utils.wrap("#\{", "}")
  end
end

defimpl Encode, for: Tag do
  def encode(tag, opts) do
    value = Encode.encode(tag.value, opts)
    "##{tag.name} #{value}"
  end
end

defimpl Encode, for: UUID do
  def encode(uuid, _opts) do
    Encode.encode(Tag.new("uuid", uuid.value))
  end
end

defimpl Encode, for: DateTime do
  def encode(datetime, _opts) do
    value = DateTime.to_string(datetime) |> String.replace(" ", "T")
    Encode.encode(Tag.new("inst", value))
  end
end

defimpl Encode, for: Date do
  def encode(date, _opts) do
    value = Date.to_iso8601(date)
    Encode.encode(Tag.new("date", value))
  end
end

defimpl Encode, for: Any do
  def encode(struct, opts) when is_map(struct) do
    case opts[:preserve_structs] do
      true -> to_tag_struct(struct, opts)
      _ -> to_plain_map(struct)
    end
    |> Encode.encode()
  end

  def encode(value, _opts) do
    raise %Protocol.UndefinedError{protocol: Encode, value: value}
  end

  defp to_tag_struct(struct, opts) do
    Eden.Tag.new(struct.__struct__, Map.from_struct(struct))
  end

  defp to_plain_map(struct) do
    Map.from_struct(struct)
  end
end
