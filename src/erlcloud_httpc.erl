-module (erlcloud_httpc).

% we cover all the request variants supported by httpc. I'm not even sure we need all of them.
-export ([request/5, request/4, request/2, request/1]).
-export ([extract_body/1]).

request(Url) -> request(Url, undefined).
request(Url, Profile) -> request(get, {Url, []}, [], [], Profile).
request(Method, Request, HTTPOptions, Options) -> request(Method, Request, HTTPOptions, Options, undefined).
request(Method, Request, HTTPOptions, Options, _Profile) ->
    % assumptions:
    % - httpc Method == hackney Method (should be true)
    % - httpc HTTPOptions ++ Options are sensible hacknet Options (*most* probably false) 
    {Url, Headers, Body} = httpc_to_hackney(Request),
    io:format("erlcloud_httpc:request/5 called for ~p", [Url]),
    Response = hackney:request(Method, Url, Headers, Body, HTTPOptions ++ Options),
    hackney_to_httpc(Response).

extract_body(ClientRef) ->
    {ok, RespBody} = hackney:body(ClientRef),
    RespBody.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hackney_to_httpc({ok, StatusCode, RespHeaders, ClientRef}) ->
    % {ok, RespBody} = hackney:body(ClientRef),
    {ok, {{'1.1', StatusCode, integer_to_list(StatusCode)}, fmt_resp_headers(RespHeaders), ClientRef}};
hackney_to_httpc({error, _Reason} = Err) ->
    Err.

httpc_to_hackney({Url, Headers}) ->
    {Url, fmt_req_headers(Headers), <<>>};
httpc_to_hackney({Url, Headers, CType, Body}) ->
    {Url, fmt_req_headers([{"content-type", CType} | Headers]), Body}.

% if we are providing some headers where both K and V are not either lists or binaries,
% too bad.
fmt_req_headers([]) -> [];
fmt_req_headers([{K, V}| Rest]) when is_list(K) andalso is_list(V) ->
    [{list_to_binary(K), list_to_binary(V)} | fmt_req_headers(Rest)];
fmt_req_headers([{K, V}| Rest]) when is_binary(K) andalso is_binary(V) ->
    [{K, V} | fmt_req_headers(Rest)].

% hackney seems to be consistent in returning binaries for both header name and value
% of course, the rest of the code expects lists (sigh)
fmt_resp_headers([]) -> [];
fmt_resp_headers([{K, V}| Rest]) ->
    [{binary_to_list(K), binary_to_list(V)} | fmt_req_headers(Rest)].
