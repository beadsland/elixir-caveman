defmodule Caveman do
  @moduledoc """
  Caveman debugging drop-in for Elixir projects.
  """

  defmacro __using__(_opts) do
    quote do
      require Logger
      import Kernel, except: [hello: 2, hello: 1, hello: 0]
      import Caveman, only: [hello: 2, hello: 1, hello: 0]
    end
  end

  @doc """
  Write a debugging checkpoint to the log. Each checkpoint provides mfa and
  line number, together with the caller's `binding()`. An optional argument
  may be provided to also be included in the checkpoint.

  By default, the variable list is formatted with the `inspect/2` option
  `pretty: true`. Additioal `Inspect.Opts` may be provided. In the event that
  there are no bound variables and no argument is provided, only the mfa and
  line are logged.

  Will raise an `ArgumentError` if opts are not provided as a Kewyord list.
  """
  @spec hello() :: Macro.t()
  @spec hello(what :: term()) :: Macro.t()
  @spec hello(what :: term(), opts :: keyword()) :: Macro.t() | none()
  defmacro hello(what \\ nil, opts \\ []) do
    quote bind_quoted: [what: what, opts: opts] do
      Caveman.keyword! opts
      if __ENV__.function do
        Logger.debug Caveman.do_hello(what, opts, binding(), __ENV__, __MODULE__)
      end
    end
  end

  @doc false
  def do_hello(what, opts, bind, env, mod) do
    where = "#{mod}.#{funcstring env} @#{env.line}"
    output = if what, do: [what: what], else: []
    output = output ++ bind
    opts = opts |> Keyword.put_new(:pretty, true)

    if output != [], do: "#{where}\n\t#{inspect(output, opts)}\n", else: "#{where}\n"
  end

  defp funcstring(%{function: nil}), do: nil
  defp funcstring(env), do: "#{elem env.function, 0}/#{elem env.function, 1}"

  @doc false
  defmacro keyword!(list) do
    quote bind_quoted: [list: list] do
      if !Keyword.keyword?(list) do
        raise ArgumentError, message: "expected keyword list, got: #{inspect list}"
      else
        true
      end
    end
  end

end
