defmodule FlameEC2Test do
  use ExUnit.Case
  doctest FlameEC2

  test "code loaded" do
    assert Code.loaded?(FlameEC2)
  end
end
