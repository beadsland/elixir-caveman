defmodule CavemanTest.Readme.Common.WalkAST do

  ###
  # Parse and replace nodes of Astract Syntax Trees
  #
  # Not a full AST implementation, but adequate for munging mix.exs files.
  ###

  def get_ast_path(ast, path), do: walk_ast_path(:get, ast, path)

  def put_ast_path(ast, path, val), do: walk_ast_path({:put, val}, ast, path)

  defp walk_ast_path(job, {head, meta, list}, [head | tail]) when is_atom(head) do
    walk = walk_ast_path job, list, tail
    case job do
      :get -> walk
      {:put, _val} -> {head, meta, walk}
    end
  end

  defp walk_ast_path(job, [{:__aliases__, _, _} = altup, list], tail) do
    walk = walk_ast_path job, list, tail
    case job do
      :get -> walk
      {:put, _val} -> [altup, walk]
    end
  end

  defp walk_ast_path(job, [do: {:__block__, meta, list}], tail) do
    walk = walk_ast_path job, list, tail
    case job do
      :get -> walk
      {:put, _val} ->
        case walk do
          [term] -> [do: term]
          _ -> [do: {:__block__, meta, walk}]
        end
    end
  end

  defp walk_ast_path(job, [do: term], tail) do
    walk = walk_ast_path job, [term], tail
    case job do
      :get -> walk
      {:put, _val} ->
        case walk do
          [term] -> [do: term]
          _ -> [do: {:__block__, [], walk}]
        end
    end
  end

  defp walk_ast_path(job,
                     [{decl, meta, [{name, _, param} = namtup | [list]]} | more],
                     [{decl, name, param} | tail]) when is_list(list) do
    walk = walk_ast_path job, list, tail
    case job do
      :get -> walk
      {:put, _val} -> [{decl, meta, [namtup | [walk]]} | more]
    end
  end

  defp walk_ast_path(job, ast, []) do
    case job do
      :get -> ast
      {:put, val} -> val
    end
  end

  defp walk_ast_path(job, [prior | list], tail) do
    walk = walk_ast_path job, list, tail
    case job do
      :get -> walk
      {:put, _val} -> [prior | walk]
    end
  end

  defp walk_ast_path(job, [], [{decl, name, param} | _] = tail) do
    case job do
      :get -> nil
      {:put, _val} ->
        walk_ast_path job, [{decl, [], [{name, [], param}, [do: []]]}], tail
    end
  end

end
