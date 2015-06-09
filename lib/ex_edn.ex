defmodule ExEdn do
  import ExEdn.Parser
  alias ExEdn.Encode
  alias ExEdn.Decode
  alias ExEdn.Exception, as: Ex

  def encode(_data) do
    raise "Unimplemented function"
  end

  def encode!(data) do
    Encode.encode(data)
  end

  def decode(input) do
    try do
      {:ok, decode!(input)}
    rescue
      e -> {:error, e.__struct__}
    end
  end

  def decode!(input) do
    tree = parse(input, location: true)
    case Decode.decode(tree) do
      [] -> raise Ex.EmptyInputError, input
      [data] -> data
      data -> data
    end
  end
end
