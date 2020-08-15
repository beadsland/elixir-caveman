# Caveman

Caveman debugging drop-in for Elixir projects. Provides macros for tracing to
stderr both in Elixir and Erlang source files.

## Usage

### Elixir

To debug Elixir files:

```elixir
  use Caveman

  def do_something(Param1, Param2) ->
    hello()

    hello("gigo", pretty: false)
```

The `hello/2` macro writes a debugging checkpoint through `Logger`. Each
checkpoint provides mfa and line number, together with the caller's `binding()`.
An optional term may be provided to also be included in the checkpoint.

By default, the variable list is formatted with the `inspect/2` option
`pretty: true`. Additional `Inspect.Opts` may be provided. In the event that
there are no bound variables and no argument is provided, only the mfa and
line are logged.

## Erlang

To debug Erlang files:

```erlang
-include_lib("deps/caveman/caveman.hrl").

do_something(Param1, Param2) ->
  ?Hello([Param2, Local1]),

  . . .

  ?Hello,
```

The `?Hello/1` macro accepts a list of local variables to be included in the
trace checkpoint. It writes to `standard_error` the mfa and line number, along
with the names and values of the variables provided.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `caveman` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:caveman, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/caveman](https://hexdocs.pm/caveman).
