
-define (Hello,
         private_caveman_hello(?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY,
         ?LINE, [], [])).

-define (Hello(List),
         private_caveman_hello(?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY,
         ?LINE, ??List, [List])).

%% This is a kludge to conform with dialyzer. Will be obviated when we integrate
%% with Elixir implemenation.
-export([private_caveman_hello/6]).

%% @hidden
private_caveman_hello(Mod, Func, Arit, Line, Names, List) ->
  try erlang:foo() catch
    _:_ -> io:fwrite(standard_error, "~p:~p/~p @~p ~s~n ~P~n~n",
                                     [Mod, Func, Arit, Line, Names, List, 20])
  end.

-dialyzer({no_missing_calls, private_caveman_hello/6}).
