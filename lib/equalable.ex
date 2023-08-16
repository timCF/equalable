defprotocol Equalable do
  @moduledoc """
  Protocol which describes symmetric equivalence relation for pair of types
  """

  @type t :: Equalable.t()

  @doc """
  Accepts struct with fields :left and :right and returns true if left is equivalent to right, else returns false
  """
  @fallback_to_any true
  @spec equal?(t) :: bool
  def equal?(left_and_right)
end

defimpl Equalable, for: Any do
  defmacro __deriving__(mod, _struct, opts) do
    unless opts[:fields], do: raise ArgumentError, """
    must supply a list of the field atoms to use in comparison for this type
    """
    quote do
      import Eq, only: [defequalable: 3]
      defequalable %{__struct__: unquote(mod)} = left :: unquote(mod), %{__struct__: unquote(mod)} = right :: unquote(mod) do
        field_getter = &Map.take(&1, unquote(opts[:fields]))
        Eq.equal?(field_getter.(left), field_getter.(right))
      end
    end
  end

	def equal?(%{left: l, right: r}) do
  	Eq.equal?(l, r)
  end
end

defmodule Eq do
  @moduledoc """
  Utilities which help to implement and use `Equalable` protocol for pair of types/values
  """

  @type left :: term
  @type right :: term

  @doc """
  Is left equivalent to right?
  Here are provided examples for standard Erlang types,
  for more complex examples look `defequalable/3` documetation.

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

  iex> a = 1
  iex> x = URI.parse("http://hello.world")
  iex> y = URI.parse("http://foo.bar")
  iex> z = URI.parse("http://foo.bar")
  iex> Eq.equal?(a, x)
  false
  iex> Eq.equal?(x, a)
  false
  iex> Eq.equal?(x, y)
  false
  iex> Eq.equal?(y, x)
  false
  iex> Eq.equal?(y, z)
  true
  iex> Eq.equal?(z, y)
  true
  ```
  """
  @spec equal?(left, right) :: bool
  def equal?(left, right) do
    lr_type =
      try do
        [Equalable, Type, Typable.type_of(left), To, Typable.type_of(right)]
        |> Module.safe_concat()
      rescue
        ArgumentError -> Equalable.ErlangType.Any
      end

    %{__struct__: lr_type, left: left, right: right}
    |> Equalable.equal?()
  end

  @doc """
  Is left not equivalent to right?
  For more complex examples look `equal?/2` and `defequalable/3` documetation.

  ## Examples

  ```
  iex> Eq.not_equal?(1, 0)
  true
  iex> Eq.not_equal?(1, 1)
  false
  ```
  """
  @spec not_equal?(left, right) :: bool
  def not_equal?(left, right) do
    not equal?(left, right)
  end

  @doc """
  Infix shortcut for `Eq.equal?/2`

  ## Examples
  ```
  iex> use Eq
  Eq
  iex> 1 <~> 1
  true
  iex> 1 <~> :hello
  false
  ```
  """
  defmacro left <~> right do
    quote do
      unquote(left)
      |> Eq.equal?(unquote(right))
    end
  end

  @doc """
  Infix shortcut for `Eq.not_equal?/2`
  ## Examples
  ```
  iex> use Eq
  Eq
  iex> 1 <|> 1
  false
  iex> 1 <|> :hello
  true
  ```
  """
  defmacro left <|> right do
    quote do
      unquote(left)
      |> Eq.not_equal?(unquote(right))
    end
  end

  @doc """
  Imports `Eq.defequalable/3`, `Eq.<~>/2` and `Eq.<|>/2` macro helpers

  ## Examples

  ```
  iex> use Eq
  Eq
  iex> 1 <~> 1
  true
  iex> 1 <|> 2
  true
  ```
  """
  defmacro __using__(_) do
    quote do
      import Eq, only: [defequalable: 3, <~>: 2, <|>: 2]
    end
  end

  @doc """
  Helper to define symmetric equivalence relation,
  accepts two `term :: type` pairs
  and block of code where relation is described.

  ## Examples

  ```
  iex> quote do
  ...>   use Eq
  ...>   defmodule Foo do
  ...>     defstruct [:value, :meta]
  ...>   end
  ...>   defmodule Bar do
  ...>     defstruct [:value, :meta]
  ...>   end
  ...>   defequalable %Foo{value: left} :: Foo, %Foo{value: right} :: Foo do
  ...>     Eq.equal?(left, right)
  ...>   end
  ...>   defequalable %Foo{value: left} :: Foo, %Bar{value: right} :: Bar do
  ...>     Eq.equal?(left, right)
  ...>   end
  ...>   defequalable %Foo{value: left} :: Foo, right :: Integer do
  ...>     Eq.equal?(left, right)
  ...>   end
  ...> end
  ...> |> Code.compile_quoted
  iex> quote do
  ...>   x = %Foo{value: 1, meta: 1}
  ...>   y = %Foo{value: 1, meta: 2}
  ...>   Eq.equal?(x, y) && Eq.equal?(y, x)
  ...> end
  ...> |> Code.eval_quoted
  ...> |> elem(0)
  true
  iex> quote do
  ...>   x = %Foo{value: 1, meta: 1}
  ...>   y = %Bar{value: 1, meta: 2}
  ...>   Eq.equal?(x, y) && Eq.equal?(y, x)
  ...> end
  ...> |> Code.eval_quoted
  ...> |> elem(0)
  true
  iex> quote do
  ...>   x = %Foo{value: 1, meta: 1}
  ...>   y = 1
  ...>   Eq.equal?(x, y) && Eq.equal?(y, x)
  ...> end
  ...> |> Code.eval_quoted
  ...> |> elem(0)
  true
  ```
  """
  defmacro defequalable(
             {:::, _, [left_expression, quoted_left_type]},
             {:::, _, [right_expression, quoted_right_type]},
             do: code
           ) do
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
          @fields [:left, :right]
          @enforce_keys @fields
          defstruct @fields
        end

        defimpl Equalable, for: unquote(lr_type) do
          def equal?(%unquote(lr_type){left: unquote(left_expression), right: unquote(right_expression)}) do
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
          @fields [:left, :right]
          @enforce_keys @fields
          defstruct @fields
        end

        defimpl Equalable, for: unquote(rl_type) do
          def equal?(%unquote(rl_type){left: unquote(right_expression), right: unquote(left_expression)}) do
            unquote(code)
          end
        end
      end
    end
  end
end
