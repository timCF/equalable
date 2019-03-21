defmodule Equalable.ErlangType.Impl do
  use Eq
  require Equalable.ErlangType.Defs, as: Helper
  Helper.define_scalars()
  Helper.define_collections()
  Helper.define_scalars_collections()

  defequalable left :: List, to: right :: List do
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

  defequalable left :: Tuple, to: right :: Tuple do
    if tuple_size(left) == tuple_size(right) do
      left
      |> Tuple.to_list()
      |> Eq.equal?(right |> Tuple.to_list())
    else
      false
    end
  end

  defequalable left :: Map, to: right :: Map do
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
