defmodule Equalable.ErlangType.Any do
  @fields [:left, :right]
  @enforce_keys @fields
  defstruct @fields
end

defimpl Equalable, for: Equalable.ErlangType.Any do
  def equal?(%Equalable.ErlangType.Any{left: %_{} = left, right: %_{} = right}) do
    left
    |> Map.from_struct()
    |> Eq.equal?(Map.from_struct(right))
  end

  def equal?(%Equalable.ErlangType.Any{left: %_{} = left, right: right}) do
    left
    |> Map.from_struct()
    |> Eq.equal?(right)
  end

  def equal?(%Equalable.ErlangType.Any{left: left, right: %_{} = right}) do
    left
    |> Eq.equal?(Map.from_struct(right))
  end
end
