#!/usr/bin/env escript
%% -*- erlang -*-

%% @doc  Platform-agnostic `touch` command.
main([]) ->
  io:fwrite(standard_error, "touch: missing file operand~n", []),
  halt(1);

main(Args) ->
  lists:foreach(fun (File) ->
    case filelib:is_file(File) of
      true ->
        case file:change_time(File, calendar:local_time()) of
          ok ->
            ok;
          {error, Reason} ->
            io:fwrite(standard_error, "touch: ~p: ~p~n", [Reason, File]),
            halt(1)
        end;
      false ->
        case file:write_file(File, "", [append]) of
          ok ->
            ok;
          {error, Reason} ->
            io:fwrite(standard_error, "touch: ~p ~p~n", [Reason, File]),
            halt(1)
        end
    end
  end, Args).
