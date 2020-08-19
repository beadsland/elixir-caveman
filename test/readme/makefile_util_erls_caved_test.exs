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

  def srcfile(mod) do
    [Common.elixir_subpath, "src", "#{mod}.erl"] |> Path.join()
  end

  def do_dropin(module) do
    {:ok, dropin} = Common.get_erlang_kernel_dropin()
    file = [Common.deps_path, srcfile(module)] |> Path.join()

    str = File.read!(file)
      |> String.replace("-module(#{module}).\n", fn x -> "#{x}\n#{dropin}\n1\n" end)
    File.write!(file, str)
  end

  def clean_dropin(module) do
    Common.revert_elixir_file(srcfile(module))
  end

  def do_caved_test do
    [File.cwd!(), "util", "elixir_erls_caved.escript"]
      |> Path.join()
      |> System.cmd([Common.deps_path])
  end

  test "detect caved kernel erl file" do
    module = @test_module1

    do_dropin(module)
    result = do_caved_test()
    clean_dropin(module)

    assert result == {Path.join(Common.deps_path, srcfile(module)), 0}
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

    assert Enum.member?(result, Path.join(Common.deps_path, srcfile(module1)))
    assert Enum.member?(result, Path.join(Common.deps_path, srcfile(module2)))
    assert length(result) == 2
  end

end
