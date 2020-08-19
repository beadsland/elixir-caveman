defmodule CavemanTest.Readme.Kernel.MakefileTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  Code.require_file Path.join(["common", "walkast.exs"]), __DIR__
  alias CavemanTest.Readme.Common.WalkAST

  ###
  # Confirm instructions included for Makefile drop-in
  ###

  test "parse README for Makefile drop-in" do
    Common.get_makefile_kernel_dropin()
  end

  def get_elixir_mixexs(depsmixfile) do
    {:ok, quot} = depsmixfile |> File.read! |> Code.string_to_quoted
    quot
  end

  def compile_elixir_mixexs(depsmixfile, quot) do
    File.write! depsmixfile, Macro.to_string(quot)
    [{MixProject, _bin}] = Code.compile_file depsmixfile
  end

  test "validly rewrite mix.exs" do
    mixfile = [Common.elixir_subpath, "mix.exs"] |> Path.join
    depsmixfile = [Common.deps_path, mixfile] |> Path.join

    compile_elixir_mixexs depsmixfile, get_elixir_mixexs(depsmixfile)
    project = apply MixProject, :project, []

    Common.revert_elixir_file mixfile

    assert project[:app] == :elixir
  end

  def strip_lines(ast) do
    Macro.prewalk(ast, fn x ->
      Macro.update_meta(x, &Keyword.delete(&1, :line)) 
    end)
  end

  def insert_from_drop([{:def, _, [{name, _, param}, doblock]} | tail], ast) do
    body = WalkAST.get_ast_path ast, [:defmodule, {:def, name, param}]
    body = if body == nil, do: [[]], else: body
    last = List.last body
    [drops] = WalkAST.get_ast_path doblock, []

    last = do_insert_from_drop drops, last
    body = List.replace_at body, -1, last
    ast = WalkAST.put_ast_path ast, [:defmodule, {:def, name, param}], body

    insert_from_drop(tail, ast)
  end

  def insert_from_drop([], ast), do: ast

  def do_insert_from_drop([{key, value} | tail], keylist) do
    case Keyword.get(keylist, key) do
      nil -> do_insert_from_drop tail, Keyword.put(keylist, key, value)
      ^value -> do_insert_from_drop tail, keylist
      current ->
        msg = "tried to replace: #{inspect current}, with: #{inspect value}"
        raise "conflicting property #{key}: #{msg}"
    end
  end

  def do_insert_from_drop([], keylist), do: keylist

  test "conform mix.exs to README" do
    mixfile = [Common.elixir_subpath, "mix.exs"] |> Path.join
    depsmixfile = [Common.deps_path, mixfile] |> Path.join
    quot = depsmixfile |> get_elixir_mixexs() |> strip_lines()

    {:ok, drop} = Common.get_mixexs_kernel_dropin
    drop = drop
      |> String.replace(". . .", "")
      |> String.replace("use Mix.Project", "")
    {:ok, drop} = "defmodule #{__MODULE__}.TestMixProject do\n#{drop}\nend"
      |> Code.string_to_quoted

    str = drop
      |> strip_lines()
      |> WalkAST.get_ast_path([:defmodule])
      |> insert_from_drop(quot)
      |> Macro.to_string
    File.write! depsmixfile, str

    result = [Common.deps_path, Common.elixir_subpath]
      |> Common.cd_cmd!("mix", ["deps.get"])
    depsgot = [Common.deps_path, Common.elixir_subpath,
               "deps", "caveman", "caveman.hrl"]
      |> Path.join
      |> File.regular?

    [Common.deps_path, Common.elixir_subpath]
      |> Common.cd_cmd!("mix", ["deps.clean", "caveman"])
    Common.revert_elixir_file mixfile

    {_stdout, 0} = result
    assert depsgot == true
  end

end
