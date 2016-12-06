-module(sive).
-export([
    sive/1
]).

-record(num,{
    val::integer(),
    state::atom()
}).

sive(Size) ->
    
    ok.

merge(List1,List2) when is_list(List1) and is_list(List2)->
    lists:zipwith(fun merge/2, List1,List2);
merge(#num{state=primary},#num{state=primary}) ->
    primary;
merge(N1,_) ->
    N1#num{state=notprimary}.