# Caveman

Caveman debugging drop-in for Elixir projects. Provides macros for tracing to
`standard_error` both in Elixir and Erlang source files.

Originally developed for spelunking within Elixir language project itself.
Instructions for using Caveman within a fork of `elixir-lang/elixir` are
provided below.

## Usage

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

### Erlang

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

The package can be installed by adding `caveman` to your list of dependencies
in `mix.exs`. Make sure `project` has a `deps` key.

```elixir
  use Mix.Project

  def project do
    [
      . . .

      deps: deps()
    ]
  end

  def deps do
    [
      {:caveman, github: "beadsland/elixir-caveman"}
    ]
  end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

## Dependencies / Unit Testing

The `test` folder for this project includes tests of the drop-in code blocks
that appear in the next section of this README file, including the additional
rules to be included in the `Makefile` of the Elixir language project when
using Caveman with same.

To facilitate these tests, the `elixir-lang` repository is included among the
test environment dependencies for Caveman. This can add upwards of 60 Mb to
the `deps` folder. These files can be modified and overwritten in the course
of unit tests, and should not be relied upon as a working copy of Elixir.

## Integration with Elixir Kernel

To use Caveman when debugging the Elixir language project, first add it as a
dependency in `lib/elixir/mix.exs`. You may also wish to add the following to
`.gitignore` to eliinate `deps` directory clutter:

```
/lib/elixir/deps
```

Next drop this into `lib/elixir/lib/kernel.ex`, somewhere near the top of the
module.

```elixir
@doc """
Drop-in entry point for bootstrap-safe Kernel debugging using Caveman.

_See__: github.com/beadsland/elixir-caveman

Should be removed before compiling for production.
"""
@compile {:inline, hello: 2}
case :code.ensure_loaded(Caveman) do
  {:module, _} ->
    defmacro hello(what \\ nil, opts \\ []) do
      quote bind_quoted: [what: what, opts: opts] do
        use Caveman
        Caveman.hello what, opts
      end
    end

  {:error, _} ->
    defmacro hello(_what \\ nil, _opts \\ []), do: :stub
end
```

The above is necessary to accommodate bootstrapping. Caveman loads only after
Elixir `Kernel` and other standard library modules have compiled, including
`Logger`. Thus, bootstrap `kernel.ex` compiles with a stub macro. We'll use a
`Makefile` rule to recompile it once bootstrapping has completed.

Moreover, the umbrella build process of the Elixir project wasn't set up to
use `mix` dependencies. Thus, to save busy work, our `Makefile` rules will get
and compile Caveman, placing its beam files alongside those of Elixir's own
modules.

Note that by placing this macro in the Kernel, we make it available to all
Elixir modules. (Obviously, this should be removed when debugging work has been
completed, as should the supporting `Makefile` rules and `mix.exs` dependency.)

### Elixir Kernel—Erlang files

Similarly, to use Caveman in the Erlang source files for the Elixir project,
use the following in any `.erl` file to be traced (again with the proviso that
same ought to be removed when debugging work is completed):

```erlang
%% Drop-in entry point for bootstrap-safe Kernel debugging using Caveman.
%%
%% _Src_: github.com/beadsland/elixir-caveman
%%
%% Should be removed before compiling for production.
-ifdef(CAVEMAN).
-include_lib("deps/caveman/caveman.hrl").
-else.
-define(Hello, ?Hello([])).
-define(Hello(_List), stub).
-endif.
```

As with our conditional compilation in `kernel.ex`, here we use preprocessor
directives to provide a stub until we recompile. This will allow bootstrapping
without having gotten the Caveman dependency, but also ensures that any Elixir
functionality leveraged by `?Hello/*` isn't called upon until bootstrapping has
completed.

### Elixir Kernel—Makefile

Finally, to wrap everything up, add rules to the Elixir project `Makefile` as
follows (extending the original rule `default: compile`):

```makefile
default: compile caveman

LIBELIXIR := lib/elixir
DEPSCAVEMAN := $(LIBELIXIR)/deps/caveman
CAVESENTINEL := $(LIBELIXIR)/ebin/.caveman.sentinel
TOUCH := $(DEPSCAVEMAN)/util/touch.escript

caveman: $(LIBELIXIR)/ebin/Elixir.Caveman.beam $(DEPSCAVEMAN)/caveman.hrl

$(LIBELIXIR)/ebin/Elixir.Caveman.beam: $(DEPSCAVEMAN)/lib/caveman.ex
	$(Q) cd $(LIBELIXIR) && ../../bin/mix deps.compile
	$(Q) $(ELIXIRC) "$(DEPSCAVEMAN)/lib/*.ex" -o $(LIBELIXIR)/ebin
	$(Q) $(TOUCH) $(LIBELIXIR)/lib/kernel.ex
	$(Q) $(MAKE) $(KERNEL)

$(DEPSCAVEMAN)/caveman.hrl $(DEPSCAVEMAN)/lib/caveman.ex: $(CAVESENTINEL)
	$(Q) echo "==> caveman (get)"
	$(Q) cd $(LIBELIXIR) && ../../bin/mix deps.get
	$(Q) $(TOUCH) $(DEPSCAVEMAN)/caveman.hrl $(DEPSCAVEMAN)/lib/caveman.ex \
	              $(shell $(DEPSCAVEMAN)/util/elixir_erls_caved.escript)
	$(Q) $(MAKE) erlang ERL_COMPILER_OPTIONS="{d, 'CAVEMAN'}"

$(CAVESENTINEL):
	$(Q) echo > $(CAVESENTINEL)
```

Again, we'll want to restore the `Makefile`, removing these added rules, when
we're done using Caveman.
