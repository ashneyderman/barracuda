
# defmodule Barracuda.Performance do
#   def before(%Barracuda.Call{} = call) do
#     {time, result} = :timer.tc(fn() ->
#       proceed(call)
#     end)
#     IO.puts "time: #{time}"
#     call
#   end
#
#   def after(%Barracuda.Call{} = call) do
#   end
# end

#
# defp before_chain(%Barracuda.Call{} = call) do
#   case Barracuda.Performance.call(call) do
#     %Barracuda.Call{}=ncall0 ->
#       case Barracuda.Validator.call(ncall0) do
#         %Barracuda.Call{}=ncall1 -> ncall1
#         _ -> raise "1"
#       end
#     _ ->
#       raise "0"
#   end
# end
#
# defp after_chain(%Barracuda.Call{} = call) do
#   case Barracuda.ResultsConverter.call(call) do
#     %Barracuda.Call{}=ncall0 ->
#       case Barracuda.Performance.call(ncall0) do
#         %Barracuda.Call{}=ncall1 -> ncall1
#         _ -> raise "1"
#       end
#     _ ->
#       raise "0"
#   end
# end
#
# def create(args) do
#   %Barracuda.Call{}
#     |> before_chain
#     |> make_call
#     |> after_chain
#
#   apply(Barracuda.HttpWrapper, unquote(verb),
#         [unquote(path), unquote(options), args, unquote(config)])
# end
#
# {time, result} = :timer.tc(fn() ->
#   case Barracuda.Validator.call(call) do
#     %Barracuda.Call{}=ncall ->
#       apply(Barracuda.HttpWrapper, unquote(verb),
#             [unquote(path), unquote(options), args, unquote(config)])
#     _ ->
#       raise("expected Barracuda.Validator.call/1 to return a Barracuda.Call, all plugs must receive a call a call")
#   end
# end)
# IO.puts "time: #{time}"
# result
#
# case Barracuda.Performance.call(call) do
#   %{}
#
#
#
# def unquote(action)(args) do
#   apply(Barracuda.HttpWrapper, unquote(verb),
#         [unquote(path), unquote(options), args, unquote(config)])
# end
#
#
# defp(plug_builder_call(conn, _)) do
#   case(match(conn, [])) do
#     %Plug.Conn{halted: true} = conn ->
#       nil
#       conn
#     %Plug.Conn{} = conn ->
#       case(dispatch(conn, [])) do
#         %Plug.Conn{halted: true} = conn ->
#           nil
#           conn
#         %Plug.Conn{} = conn ->
#           conn
#         _ ->
#           raise("expected dispatch/2 to return a Plug.Conn, all plugs must receive a connection (conn) and return a connection")
#       end
#     _ ->
#       raise("expected match/2 to return a Plug.Conn, all plugs must receive a connection (conn) and return a connection")
#   end
# end

#
# timer
# defp link(next, params, opts) do
#   {time, result} = :timer.tc(fn ->
#       next(params, opts)
#     end)
#   IO.puts "time: #{inspect time} us"
#   result
# end
#
# retry
# defp link(next, params, opts) do
#   if next(params, opts) != success do
#     
#   else
#     result
#   end
# end
#
# create :user_repos,
#   f = interceptor_chain
#   |> Enum.reduce(call_handler, fn(link, acc) ->
#       fn(params, opts) ->
#         apply(link, :link, [acc, params, opts])
#       end
#      end)
#   
#   f.(params, opts)
#  
