defmodule CavemanTest.Readme.Common do

  require Logger

  def get_erlang_kernel_dropin() do
    get_readme_code "erlang", "-ifdef(CAVEMAN)."
  end

  def get_elixir_kernel_dropin() do
    get_readme_code "elixir", "defmacro hello"
  end

  def get_makefile_kernel_dropin() do
    get_readme_code "makefile", "default: compile caveman"
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
