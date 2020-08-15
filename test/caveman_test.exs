defmodule CavemanTest do
  use ExUnit.Case
  doctest Caveman

  use Caveman

  import ExUnit.CaptureLog

  ###
  # Checkpoint functionality
  ###

  test "basic trace checkpoint" do
    {func, arity} = __ENV__.function
    line = __ENV__.line + 2
    assert capture_log(fn ->
      hello()
    end) =~ "#{__MODULE__}.#{func}/#{arity} @#{line}"
  end

  test "binding in trace checkpoint" do
    a = 1; b = 2
    assert capture_log(fn ->
      hello()
    end) =~ "[a: 1, b: 2]\n\n"
    _ = a; _ = b
  end

  test "argument in trace checkpoint" do
    assert capture_log(fn ->
      hello({:what, :is, :this})
    end) =~ "[what: {:what, :is, :this}]\n\n"
  end

  test "ignore nil argument in trace checkpoint" do
    a = 1
    assert capture_log(fn ->
      hello(nil)
    end) =~ "[a: 1]\n\n"
    _ = a
  end

  test "omit variables if none trace checkpoint" do
    assert capture_log(fn ->
      hello()
    end) =~ "@#{__ENV__.line - 1}\n\n"
  end

  test "inspect options in trace checkpoint" do
    a = 10
    assert capture_log(fn ->
      hello(nil, [base: :hex])
    end) =~ "[a: 0xA]\n\n"
    _ = a
  end

  test "inspect pretty default in trace checkpoint" do
    a = [apple: "apple", berry: "berry", cherry: "cherry", date: "date", elderberry: "elderberry"]
    assert capture_log(fn ->
      hello()
    end) =~ "a: [\n    apple:"
  end

  test "inspect pretty override in trace checkpoint" do
    a = [apple: "apple", berry: "berry", cherry: "cherry", date: "date", elderberry: "elderberry"]
    assert capture_log(fn ->
      hello(nil, [pretty: false])
    end) =~ "a: [apple:"
  end

end
