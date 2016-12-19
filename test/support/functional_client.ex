defmodule Functional.Client.Timer do
  @behaviour Barracuda.Client.Interceptor
  
  def link(next, params) do
    IO.puts "timer interceptor ..."
    {time, result} = :timer.tc(fn ->
       next.(["Functional.Client.Timer.link" | params])
    end)
    IO.puts "time: #{inspect time} us"
    ["Functional.Client.Timer.link:result" | result]
  end
  
end

defmodule Functional.Client do
  
  #
  # retry
  def retry(next, params) do
    IO.puts "retry interceptor ..."
    try do
      result = next.(["retry" | params])
      ["retry:result" | result]
    catch
      _k, _e ->
        IO.puts "Let's retry it ..."
        retry(next, ["retry" | params])
    end
  end
  
  def do_user_repos(nil, params) do
    if rem(:random.uniform(100), 2) == 0 do
      IO.puts "user_repos: raising expection"
      raise "just for the heck of it"
    else
      IO.puts "user_repos: #{inspect params}"
      ["do_user_repos" | params]
    end
  end
  
  def user_repos_purely_functional() do
    user_repos_purely_functional([])
  end
  def user_repos_purely_functional(args) do
    :random.seed(:os.timestamp)
    f = [Functional.Client.Timer, &retry/2, &do_user_repos/2]
    |> Enum.reverse
    |> Enum.reduce(nil,
                   fn(link, acc) when is_function(link) ->
                       fn(params) -> link.(acc, params) end
                     (link, acc) ->
                       fn(params) -> apply(link, :link, [acc, params]) end
                   end)
    f.(args)
  end
  
  def user_repos_unfolded_functional() do
    user_repos_unfolded_functional([])
  end
  def user_repos_unfolded_functional(args) do
    :random.seed(:os.timestamp)
    Functional.Client.Timer.link(
      fn(params1) ->
        retry(fn(params0) ->
                do_user_repos(nil,params0)
              end, params1)
      end,
      %Barracuda.Client.Call{ args: args })
  end
  
  def __f0(params, action) do
    IO.puts "__f0: #{inspect action}"
    apply(__MODULE__, action, [nil, params])
  end
  
  def __f1(params, action) do
    retry(fn(p) ->
           __f0(p, action)
          end, params)
  end
  
  def __f2(params, action) do
    Functional.Client.Timer.link(
      fn(p) ->
        __f1(p, action)
      end, params)
  end
  
  def user_repos_shaped_for_macros() do
    user_repos_shaped_for_macros([])
  end
  def user_repos_shaped_for_macros(params) do
    :random.seed(:os.timestamp)
    IO.puts "test2"
    __f2(params, :do_user_repos)
  end
      
end
