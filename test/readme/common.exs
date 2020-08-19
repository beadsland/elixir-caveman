defmodule CavemanTest.Readme.Common do

  ###
  # Work with elixir-lang project in deps and with Elixir build thereunder.
  ###

  def deps_path, do: ["deps", "elixir"] |> Path.join
  def elixir_subpath, do: ["lib", "elixir"] |> Path.join

  def revert_elixir_file(filename) do
    {_stdout, 0} = cd_cmd! deps_path(), "git", ["co", filename]
  end

  def cd_cmd!(cdpath, cmd, args) when is_list(cdpath) do
    cd_cmd!(Path.join(cdpath), cmd, args)
  end

  def cd_cmd!(cdpath, cmd, args) do
    File.cd!(cdpath, fn ->
      System.cmd cmd, args, stderr_to_stdout: true
    end)
  end

  ###
  # Extract code blocks from README file.
  ###

  def get_erlang_kernel_dropin() do
    get_readme_code "erlang", "-ifdef(CAVEMAN)."
  end

  def get_elixir_kernel_dropin() do
    get_readme_code "elixir", "defmacro hello"
  end

  def get_makefile_kernel_dropin() do
    get_readme_code "makefile", "default: compile caveman"
  end

  def get_mixexs_kernel_dropin() do
    get_readme_code "elixir", "use Mix.Project"
  end

  defp get_readme_code(class, substr) do
    {:ok, ast, _} = File.read!("README.md") |> EarmarkParser.as_ast()
    ast = ast
      |> Enum.filter(fn x -> elem(x, 0) == "pre" end)
      |> Enum.map(fn x -> elem(x, 2) end)
      |> List.flatten
      |> Enum.filter(fn x -> elem(x, 0) == "code" end)
      |> Enum.map(fn x -> {elem(x, 1), elem(x, 2)} end)
      |> Enum.filter(fn x -> elem(x, 0) == [{"class", class}] end)
      |> Enum.map(fn x -> elem(x, 1) |> List.first end)
      |> Enum.filter(fn x -> String.contains?(x, substr) end)

    case length(ast) do
      0 -> {:error, :not_found}
      1 -> {:ok, List.first(ast)}
      _ -> {:error, :too_many}
    end
  end

end
