defmodule EqualableTest do
  use ExUnit.Case
  doctest Equalable

  test "greets the world" do
    assert Equalable.hello() == :world
  end
end
