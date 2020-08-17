#!/usr/bin/env escript
%% -*- erlang -*-

main([]) -> main(["."]);

main([Path]) ->
  Fileglob = filename:join([Path, "lib", "elixir", "src", "*.erl"]),
  Erls = filelib:wildcard(Fileglob),
  Caved = lists:filter(fun (X) ->
    {ok, Bin} = file:read_file(X),
    case string:find(Bin, "deps/caveman/caveman.hrl") of
      nomatch -> false;
      _ -> true
    end
  end, Erls),
  Result = string:join(Caved, " "),
  io:put_chars(Result).
