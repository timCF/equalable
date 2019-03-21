defmodule Equalable.ErlangType.Any do
  @fields [:left, :right]
  @enforce_keys @fields
  defstruct @fields
end

defimpl Equalable, for: Equalable.ErlangType.Any do
  # we assume that all standard erlang types are listed in
  # Equalable.ErlangType.Defs.scalars and Equalable.ErlangType.Defs.collections
  # then this code is safe and can't cause infinite recursion
  #
  # TODO : maybe take standard types from Typable package to make it more safe
  #
  def equal?(%Equalable.ErlangType.Any{left: left, right: right}) do
    left
    |> maybe2map
    |> Eq.equal?(maybe2map(right))
  end

  defp maybe2map(%_{} = struct), do: Map.from_struct(struct)
  defp maybe2map(some), do: some
end
