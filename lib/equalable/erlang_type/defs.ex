defmodule Equalable.ErlangType.Defs do
  use Eq

  defmacro scalars do
    [
      Atom,
      BitString,
      Float,
      Function,
      Integer,
      PID,
      Port,
      Reference
    ]
  end

  defmacro collections do
    [
      Tuple,
      List,
      Map
    ]
  end

  @doc """
  Helper to define scalar to scalar equivalence relation
  """
  defmacro define_scalars do
    code =
      scalars()
      |> Stream.with_index()
      |> Enum.flat_map(fn {left_type, left_index} ->
        {_, [_ | _] = right_list} = Enum.split(scalars(), left_index)

        right_list
        |> Enum.map(fn right_type ->
          quote do
            defequalable unquote(left_type), to: unquote(right_type) do
              var!(left) == var!(right)
            end
          end
        end)
      end)

    quote do
      (unquote_splicing(code))
    end
  end

  @doc """
  Helper to define collection to collection equivalence relation
  """
  defmacro define_collections do
    code =
      collections()
      |> Stream.with_index()
      |> Enum.flat_map(fn {left_type, left_index} ->
        {_, right_list} = Enum.split(collections(), left_index + 1)

        right_list
        |> Enum.map(fn right_type ->
          quote do
            defequalable unquote(left_type), to: unquote(right_type) do
              var!(left) == var!(right)
            end
          end
        end)
      end)

    quote do
      (unquote_splicing(code))
    end
  end

  @doc """
  Helper to define scalar to collection equivalence relation
  """
  defmacro define_scalars_collections do
    code =
      scalars()
      |> Enum.flat_map(fn left_type ->
        collections()
        |> Enum.map(fn right_type ->
          quote do
            defequalable unquote(left_type), to: unquote(right_type) do
              var!(left) == var!(right)
            end
          end
        end)
      end)

    quote do
      (unquote_splicing(code))
    end
  end
end
