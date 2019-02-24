defprotocol Equalable do
  @moduledoc """
  Protocol which describes equivalence relation
  """

  @type t :: Equalable.t()

  @doc """
  Accepts struct with fields :left and :right and returns true if left is equivalent to right, else returns false
  """
  @spec equal?(t) :: bool
  def equal?(left_and_right)
end

defmodule Eq do
  @type left :: term
  @type right :: term

  @doc """
  Is left equivalent to right?

  ## Examples

  ```
  iex> Eq.equal?(1, 1)
  true
  iex> Eq.equal?(1, 1.0)
  true
  iex> Eq.equal?(1, 2)
  false
  iex> Eq.equal?(1, :hello)
  false

  iex> Eq.equal?([1, 2, 3], [1, 2, 3])
  true
  iex> Eq.equal?([[1, 2, 3], [4]], [[1, 2, 3], [4]])
  true
  iex> Eq.equal?([1, 2, 3], [1, 2])
  false
  iex> Eq.equal?([[1, 2, 3], [4]], [[1, 2, 3], [5]])
  false

  iex> Eq.equal?({1, 2, 3}, {1, 2, 3})
  true
  iex> Eq.equal?({{1, 2, 3}, {4}}, {{1, 2, 3}, {4}})
  true
  iex> Eq.equal?({1, 2, 3}, {1, 2})
  false
  iex> Eq.equal?({{1, 2, 3}, {4}}, {{1, 2, 3}, {5}})
  false

  iex> Eq.equal?(%{a: 1, b: 2}, %{a: 1, b: 2})
  true
  iex> Eq.equal?(%{a: 1, b: %{c: 2}}, %{a: 1, b: %{c: 2}})
  true
  iex> Eq.equal?(%{a: 1, b: 2}, %{a: 1})
  false
  iex> Eq.equal?(%{a: 1, b: 2}, %{a: 1, c: 2})
  false
  ```
  """
  @spec equal?(left, right) :: bool
  def equal?(left, right) do
    lr_type =
      [Equalable, Type, Typable.type_of(left), To, Typable.type_of(right)]
      |> Module.safe_concat()

    %{__struct__: lr_type, left: left, right: right}
    |> Equalable.equal?()
  end

  @doc """
  Imports `Eq.defequalable/3` macro helper
  """
  defmacro __using__(_) do
    quote do
      import Eq, only: [defequalable: 3]
    end
  end

  @doc """
  Helper to define symmetric equivalence relation, accepts 2 types (`left` type  and `right` type)
  and block of code where relation is described via `left` and `right` variables
  """
  defmacro defequalable(quoted_left_type, [to: quoted_right_type], do: code) do
    {left_type, []} = Code.eval_quoted(quoted_left_type, [], __CALLER__)

    {right_type, []} = Code.eval_quoted(quoted_right_type, [], __CALLER__)

    lr_type =
      [Equalable, Type, left_type, To, right_type]
      |> Module.concat()

    rl_type =
      [Equalable, Type, right_type, To, left_type]
      |> Module.concat()

    lr_impl =
      quote do
        defmodule unquote(lr_type) do
          defstruct [:left, :right]
        end

        defimpl Equalable, for: unquote(lr_type) do
          def equal?(%unquote(lr_type){left: var!(left), right: var!(right)}) do
            unquote(code)
          end
        end
      end

    if lr_type == rl_type do
      lr_impl
    else
      quote do
        unquote(lr_impl)

        defmodule unquote(rl_type) do
          defstruct [:left, :right]
        end

        defimpl Equalable, for: unquote(rl_type) do
          def equal?(%unquote(rl_type){left: var!(right), right: var!(left)}) do
            unquote(code)
          end
        end
      end
    end
  end
end

defmodule Equalable.ErlangType.Defs do
  use Eq

  @scalars [
    Atom,
    BitString,
    Float,
    Function,
    Integer,
    PID,
    Port,
    Reference
  ]

  @collections [
    Tuple,
    List,
    Map
  ]

  defmacro define_scalars do
    code =
      @scalars
      |> Stream.with_index()
      |> Enum.flat_map(fn {left_type, left_index} ->
        {_, [_ | _] = right_list} = Enum.split(@scalars, left_index)

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

  defmacro define_collections do
    code =
      @collections
      |> Stream.with_index()
      |> Enum.flat_map(fn {left_type, left_index} ->
        {_, right_list} = Enum.split(@collections, left_index + 1)

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

  defmacro define_scalars_collections do
    code =
      @scalars
      |> Enum.flat_map(fn left_type ->
        @collections
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

defmodule Equalable.ErlangType.Impl do
  use Eq
  require Equalable.ErlangType.Defs, as: Helper
  Helper.define_scalars()
  Helper.define_collections()
  Helper.define_scalars_collections()

  defequalable List, to: List do
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

  defequalable Tuple, to: Tuple do
    if tuple_size(left) == tuple_size(right) do
      left
      |> Tuple.to_list()
      |> Eq.equal?(right |> Tuple.to_list())
    else
      false
    end
  end

  defequalable Map, to: Map do
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
