defmodule Baz do
  @derive {Equalable, fields: [:a]}
  defstruct [:a, :b]
end

defmodule Boo do
  defstruct [:foo]
end

defmodule EqualableTest do
  use ExUnit.Case
  doctest Equalable
  doctest Eq
  doctest Equalable.ErlangType.Defs
  doctest Equalable.ErlangType.Impl

  describe "derive tests" do
    test "works" do
      assert Eq.equal?(%Baz{a: 4}, %Baz{a: 4})
      refute Eq.equal?(%Baz{a: 1}, %Baz{a: 4, b: 1})
    end

    test "fields is a required option" do
      assert_raise(ArgumentError, fn ->
        require Protocol
        Protocol.derive(Equalable, Boo, [])
      end)
    end
  end
end
