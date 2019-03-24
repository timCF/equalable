# Equalable

Protocol which describes equivalence relation. Implementation is made for pair of types (it is **symmetric**). There are cases where we want to define equivalence relation between two terms not just by term values according standard Erlang/Elixir [equivalence rules](https://hexdocs.pm/elixir/Kernel.html#==/2) but to use some meaningful business logic to do it. Main purpose of this package is to provide extended versions of standard Kernel functions like `==/2`, `!=/2` which will rely on Equalable protocol implementation for given pair of types. Protocol itself is pretty similar to [Eq](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Eq.html) Haskell type class (but can be applied to pair of values of different types as well).

[![Hex](https://raw.githubusercontent.com/tim2CF/static-asserts/master/build-passing.svg?sanitize=true)](https://hex.pm/packages/equalable/)
[![Documentation](https://raw.githubusercontent.com/tim2CF/static-asserts/master/documentation-passing.svg?sanitize=true)](https://hexdocs.pm/typable/)

## Installation

The package can be installed by adding `equalable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:equalable, "~> 0.1.0"}
  ]
end
```

## Example

Kernel `==/2` function work pretty fine with standard numeric types like integer or float (and it works even in nested terms like map):

```elixir
iex> %{a: 1} == %{a: 1.0}
true
```

But if we try to apply Kernel `==/2` function to terms containing custom Decimal numbers it will not work so good:

```elixir
iex(1)> %{a: Decimal.new("1")} == %{a: Decimal.new("1.0")}
false
```

This is because the same decimal number can be presented as different Elixir term:

```elixir
iex> Decimal.new("1") |> Map.from_struct
%{coef: 1, exp: 0, sign: 1}
iex> Decimal.new("1.0") |> Map.from_struct
%{coef: 10, exp: -1, sign: 1}
```

And here Equalable protocol can help us. Let's implement equivalence relation between Decimal and Integer, Float and BitString types using existing `Decimal.equal?/2` helper:

```elixir
use Eq

defequalable left :: Decimal, right :: Decimal do
  Decimal.equal?(left, right)
end

defequalable left :: Integer, right :: Decimal do
  left
  |> Decimal.new()
  |> Decimal.equal?(right)
end

defequalable left :: Float, right :: Decimal do
  left
  |> Decimal.from_float()
  |> Decimal.equal?(right)
end

defequalable left :: BitString, right :: Decimal do
  left
  |> Decimal.new()
  |> Decimal.equal?(right)
end
```

And then we can use `Eq.equal?/2` utility function instead of Kernel `==/2`:

```elixir
iex> Eq.equal?(Decimal.new("1"), Decimal.new("1.0"))
true
iex> Eq.equal?(Decimal.new("1.0"), Decimal.new("1"))
true

iex> Eq.equal?(Decimal.new("1"), 1)
true
iex> Eq.equal?(1, Decimal.new("1"))
true

iex> Eq.equal?(Decimal.new("1"), 1.0)
true
iex> Eq.equal?(1.0, Decimal.new("1"))
true

iex> Eq.equal?(Decimal.new("1"), "1.0")
true
iex> Eq.equal?("1.0", Decimal.new("1"))
true

iex> Eq.equal?("1.0", Decimal.new("1.1"))
false
```

which works as expected according meaning of Decimal numbers instead of just term values. Equivalence relation based on Eualable protocol is very useful when for example we compare big nested structures which contain Decimals or other custom types (like Date, Time, NaiveDateTime, URI etc) in nested collections like lists, maps, tuples or other data types:

```elixir
iex> x0 = %{a: [%{b: Decimal.new("1")}]}
%{a: [%{b: #Decimal<1>}]}
iex> x1 = %{a: [%{b: Decimal.new("1.0")}]}
%{a: [%{b: #Decimal<1.0>}]}
iex> x0 == x1
false
iex> Eq.equal?(x0, x1)
true
```

If Equalable protocol is not defined for pair of given types then `Eq.equal?/2` function fallbacks to Kernel `==/2`:

```elixir
iex> x0 = URI.parse("https://hello.world")
%URI{
  authority: "hello.world",
  fragment: nil,
  host: "hello.world",
  path: nil,
  port: 443,
  query: nil,
  scheme: "https",
  userinfo: nil
}
iex> x1 = "https://hello.world"
"https://hello.world"
iex> x0 == x1
false
iex> Eq.equal?(x0, x1)
false
```
