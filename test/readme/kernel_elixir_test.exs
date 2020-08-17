defmodule CavemanTest.Readme.Kernel.ElixirTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  import ExUnit.CaptureLog

  ###
  # Confirm instructions included for Elixir Kernel drop-in
  ###

  test "parse README for Elixir Kernel drop-in" do
    {:ok, _str} = Common.get_elixir_kernel_dropin()
  end

  def get_compiler_case_pattern() do
    {:ok, str} = Common.get_elixir_kernel_dropin()
    {:ok, quot} = Code.string_to_quoted str
    get_compiler_case_pattern quot
  end

  def get_compiler_case_pattern({:__block__, [], ast}) do
    get_compiler_case_pattern(nil, ast)
  end

  def get_compiler_case_pattern(nil, [{:@, _, [{:compile, _,
                                               [inline: [hello: 2]]}]} | ast]) do
    get_compiler_case_pattern(:inline, ast)
  end

  def get_compiler_case_pattern(nil, [_ | tail]) do
    get_compiler_case_pattern(nil, tail)
  end

  def get_compiler_case_pattern(:inline, [{:case, _, case} | _]) do
    get_compiler_case_pattern(:case, case)
  end

  def get_compiler_case_pattern(:inline, _) do
     {:error, :compile_without_case}
   end

  def get_compiler_case_pattern(:case, [{{:., _, [:code, :ensure_loaded]}, _,
                                         [{:__aliases__, _, [:Caveman]}]} | casedo]) do
    get_compiler_case_pattern(:casedo, casedo)
  end

  def get_compiler_case_pattern(:casedo, [[do: clauses]]) do
    get_compiler_case_pattern(:clauses, clauses)
  end

  def get_compiler_case_pattern(:clauses, clauses) do
    macros = clauses |> Enum.map(fn x ->
      {:->, _, [[{atom, _}], hello]} = x
      {atom, hello}
    end)
    {:ok, macros}
  end

  test "valid @compile/case pattern in README Elixir Kernel drop-in" do
    {:ok, macros} = get_compiler_case_pattern()
    assert Keyword.has_key? macros, :module
    assert Keyword.has_key? macros, :error
  end

  ###
  # Confirm both clauses of Elixir Kernel drop-in work as expected
  ###

  defmodule CompilerClauseTest, do: :ok

  def recompile_module(str) when is_binary(str) do
    str |> Code.string_to_quoted() |> recompile_module()
  end

  def recompile_module(quot) do
    Code.compiler_options(ignore_module_conflict: true)
    Code.compile_quoted(quot)
    Code.compiler_options(ignore_module_conflict: false)
  end

  def build_compiler_case(case) do
    compilerClause = "#{__MODULE__}.CompilerClause_#{case}"
    compilerClauseTest = "#{compilerClause}Test"
    {:ok, macros} = get_compiler_case_pattern()
    {:ok, modname} = Code.string_to_quoted compilerClause
    ast = {:defmodule, [], [modname, [do: macros[case]]]}
    recompile_module(ast)

    str = """
    defmodule #{compilerClauseTest} do
      import Kernel, except: [hello: 2, hello: 1, hello: 0]
      import #{compilerClause}, only: [hello: 0]
      def test, do: hello()
    end
    """
    recompile_module(str)

    String.to_atom compilerClauseTest
  end

  test "valid stub macro in README Elixir Kernel drop-in" do
    module = build_compiler_case(:error)
    assert module.test() == :stub
  end

  test "valid post-bootstrapping macro in README Elixir Kernel drop-in" do
    module = build_compiler_case(:module)
    assert capture_log(fn ->
      module.test()
    end) =~ "#{module}.test/0 @4"
  end

end
