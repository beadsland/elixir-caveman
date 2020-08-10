defmodule CavemanTest do
  use ExUnit.Case
  doctest Caveman

  test "greets the world" do
    assert Caveman.hello() == :world
  end
end
