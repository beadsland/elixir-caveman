
-define (Hello, try erlang:foo() catch
  _:_ -> io:fwrite(standard_error, "~p:~p/~p @~p~n~n",
         [?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, ?LINE])
end).

-define (Hello(List), try erlang:foo() catch
  _:_ -> io:fwrite(standard_error, "~p:~p/~p ~~~p ~p~n ~P~n~n",
         [?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, ?LINE, ??List, List, 20])
end).
