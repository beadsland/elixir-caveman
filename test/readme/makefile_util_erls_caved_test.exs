defmodule CavemanTest.Readme.Makefile.Util.ErlsCavedTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  # To avoid race conditions between async tests, make sure these tests and
  # those for makefile proper don't meddle with same Erlang source files.
  @test_module1 "elixir_dispatch"
  @test_module2 "elixir_errors"

  ###
  # Test detection of Caveman include_libs in Kernel Erlang source files
  ###

  def deppath, do: ["deps", "elixir"] |> Path.join()

  def srcfile(mod), do: ["lib", "elixir", "src", "#{mod}.erl"] |> Path.join()

  def do_dropin(module) do
    {:ok, dropin} = Common.get_erlang_kernel_dropin()
    file = [deppath(), srcfile(module)] |> Path.join()

    str = File.read!(file)
      |> String.replace("-module(#{module}).\n", fn x -> "#{x}\n#{dropin}\n1\n" end)
    File.write!(file, str)
  end

  def clean_dropin(module) do
    File.cd!(deppath(), fn ->
      {_stdout, 0} = System.cmd "git", ["co", srcfile(module)]
    end)
  end

  def do_caved_test do
    [File.cwd!(), "util", "elixir_erls_caved.escript"]
      |> Path.join()
      |> System.cmd([deppath()])
  end

  test "detect caved kernel erl file" do
    module = @test_module1

    do_dropin(module)
    result = do_caved_test()
    clean_dropin(module)

    assert result == {Path.join(deppath(), srcfile(module)), 0}
  end

  test "detect multiple caved kernel erl files" do
    module1 = @test_module1
    module2 = @test_module2

    do_dropin(module1)
    do_dropin(module2)
    result = do_caved_test()
    clean_dropin(module1)
    clean_dropin(module2)

    {stdout, 0} = result
    result = String.split(stdout, " ")

    assert Enum.member?(result, Path.join(deppath(), srcfile(module1)))
    assert Enum.member?(result, Path.join(deppath(), srcfile(module2)))
    assert length(result) == 2
  end

end
