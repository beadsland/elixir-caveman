%% @hidden This is just used for dialyzer testing.
-module(caveman_dialyzer_warning).
-export([test/0]).

-include_lib("caveman.hrl").
 
%% If caveman.hrl is set up properly, this should *not* generate a dialyzer warning.
test() -> ?Hello.
