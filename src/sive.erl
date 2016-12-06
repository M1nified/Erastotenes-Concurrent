-module(sive).
-export([
    sive/1
]).
-compile(export_all).
-include_lib("eunit/include/eunit.hrl").

-define(MAX, 100).

-record(num,{
    val::integer(),
    state=primary::atom()
}).

sive(Size) ->
    ok.

process_number(Map,Number) when is_map(Map) and is_integer(Number) ->
    % io:fwrite("Map with ~p is ~p\n",[Number,Map]),
    io:fwrite("process_number ~p \n",[Number]),
    case maps:get(Number,Map,undefined) of
        notprimary ->
            process_number(Map,Number+1);
        _ ->
            Count = concurrent_run(Map,Number,1),
            Map2 = wait_for_data(Map,Number,Count),
            process_number(Map2,Number+Number)
    end.

concurrent_process_number(From,Map,Number) when Number < ?MAX ->
    io:fwrite("SPAWN HERE ~p\n",[Number]),
    Map2 = clear(Map,Number,Number),
    % io:fwrite("Map2 for ~p is ~p\n",[Number, Map2]),
    From ! {data, Map2},
    ok;
concurrent_process_number(_,_,_) ->
    ok.

concurrent_run(Map,Number,Step) when Step < 2*Number->
    case maps:get(Number+Step,Map,undefined) of
        notprimary ->
            concurrent_run(Map,Number,Step+1);
        _ ->
            Me = self(),
            spawn(fun() -> concurrent_process_number(Me,Map,Number+Step) end),
            1 + concurrent_run(Map,Number,Step+1)
    end;
concurrent_run(_,_,_) ->
    0.

wait_for_data(Map,_,0) ->
    Map;
wait_for_data(Map,Number,Count) ->
    receive
        {data,Map2} ->
            % io:fwrite("RECEIVED: ~p\n",[Map2]),
            Map3 = maps:merge(Map,Map2),
            wait_for_data(Map3,Number,Count-1)
    end.


clear(Map,_,Start) when Start > ?MAX ->
    Map;
clear(Map,Number,Start) when Number =:= Start ->
    clear(Map,Number,Start+Number);
clear(Map,Number,Start) when is_map(Map) and is_integer(Number)->
    case Start rem Number of
        0 ->
            % io:fwrite("clear(~p,~p,~p) 0 \n",[Map,Number,Start]),
            MapCleared = maps:put(Start,notprimary,Map),
            clear(MapCleared,Number,Start+Number);
        _ ->
            % io:fwrite("clear(~p,~p,~p) _ \n",[Map,Number,Start]),
            clear(Map,Number,Start+Number)
    end.

% merge(List1,List2) when is_list(List1) and is_list(List2)->
%     lists:zipwith(fun merge/2, List1,List2);
% merge(#num{val=Val,state=primary},#num{state=primary}) ->
%     #num{val=Val,state=primary};
% merge(N1,_) ->
%     N1#num{state=notprimary}.

% merge_should_return_notprimary__test() ->
%     #num{val=1,state=notprimary} = merge(#num{val=1,state=primary},#num{state=notprimary}).
% merge_should_return_primary__test() ->
%     #num{val=1,state=primary} = merge(#num{val=1,state=primary},#num{val=1,state=primary}).
% merge_should_merge__test() ->
%     [#num{val=1,state=notprimary},#num{val=2,state=primary},#num{val=3,state=primary}] = merge([#num{val=1,state=notprimary},#num{val=2,state=primary},#num{val=3,state=primary}],[#num{val=1,state=primary},#num{val=2,state=primary},#num{val=3,state=primary}]).