defmodule CavemanTest.Readme.Kernel.ErlangTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  import ExUnit.CaptureIO

  ###
  # Confirm instructions included for Erlang Kernel drop-in
  ###

  def get_erlang_kernel_dropin() do
    Common.get_readme_code "erlang", "-ifdef(CAVEMAN)."
  end

  test "parse README for Erlang Kernel drop-in" do
    {:ok, _str} = get_erlang_kernel_dropin()
  end

  def compile_erlang_preprocessor_pattern(module, is_stub \\ true) do
    module = Atom.to_string module
    {:ok, str} = get_erlang_kernel_dropin()

    str = """
      %% coding: latin-1
      -module(#{module}).
      -export([test/0]).
      #{str}
      test() -> ?Hello.
    """

    filename = System.tmp_dir!() |> Path.join("#{module}.erl")
    File.write! filename, str, [:latin1]

    opts = if is_stub, do: [], else: [{:d, :CAVEMAN}]
    outdir = ["_build", "test", "lib", "caveman", "ebin"]
      |> Path.join()
      |> String.to_charlist()
    opts = [{:outdir, outdir}] ++ opts
    filename |> String.to_charlist() |> :compile.file(opts)
  end

  test "valid preprocessor pattern in README Erlang Kernel drop-in" do
    module = :caveman_preprocessor_test
    {:ok, ^module} = compile_erlang_preprocessor_pattern module
  end

  test "valid stub macro in README Erlang Kernel drop-in" do
    module = :caveman_preprocessor_stub_test
    {:ok, ^module} = compile_erlang_preprocessor_pattern module
    assert :stub == module.test()
  end

  test "valid post-deps.get macro in README Erlang Kernel drop-in" do
    File.mkdir("deps")
    File.cwd! |> File.ln_s("deps/caveman")
    module = :caveman_preprocessor_depsget_test
    {:ok, ^module} = compile_erlang_preprocessor_pattern module, false

    assert capture_io(:standard_error, fn ->
      module.test()
    end) =~ "#{module}:test/0 @15"
  end

end
