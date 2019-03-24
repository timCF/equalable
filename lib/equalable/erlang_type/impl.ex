defmodule Equalable.ErlangType.Impl do
  use Eq
  require Equalable.ErlangType.Defs, as: Helper
  Helper.define_scalars()
  Helper.define_collections()
  Helper.define_scalars_collections()

  (Helper.scalars() ++ Helper.collections())
  |> Enum.each(fn type ->
    defimpl Equalable, for: type do
      def equal?(v) do
        "Can not apply Equalable protocol to plain value #{inspect(v)} of type #{unquote(type)}, use `Eq.defequalable/3` macro helper to implement protocol"
        |> raise
      end
    end
  end)

  defequalable left :: List, right :: List do
    if length(left) == length(right) do
      left
      |> Stream.zip(right)
      |> Enum.reduce_while(true, fn {lx, rx}, true ->
        lx
        |> Eq.equal?(rx)
        |> case do
          true = acc -> {:cont, acc}
          false = acc -> {:halt, acc}
        end
      end)
    else
      false
    end
  end

  defequalable left :: Tuple, right :: Tuple do
    if tuple_size(left) == tuple_size(right) do
      left
      |> Tuple.to_list()
      |> Eq.equal?(right |> Tuple.to_list())
    else
      false
    end
  end

  defequalable left :: Map, right :: Map do
    if map_size(left) == map_size(right) do
      left
      |> Stream.zip(right)
      |> Enum.reduce_while(true, fn {lx, rx}, true ->
        lx
        |> Eq.equal?(rx)
        |> case do
          true = acc -> {:cont, acc}
          false = acc -> {:halt, acc}
        end
      end)
    else
      false
    end
  end
end
