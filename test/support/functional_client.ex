defmodule Functional.Client do
  
  #
  # timer
  defp timer(next, params, opts) do
    IO.puts "timer interceptor ..."
    {time, result} = :timer.tc(fn ->
       next.(params, opts)
    end)
    IO.puts "time: #{inspect time} us"
    result
  end

  #
  # retry
  defp retry(next, params, opts) do
    IO.puts "retry interceptor ..."
    try do
      next.(params, opts)
    catch
      k, e ->
        IO.puts "Let's retry it ..."
        retry(next, params, opts)
    end
  end
  
  defp do_user_repos(nil, params, opts) do
    if rem(:random.uniform(100), 2) == 0 do
      raise "just for the heck of it"
    else
      IO.puts "user_repos: #{inspect params}, #{inspect opts}"
      params
    end
  end
  
  def user_repos(args, options) do
    :random.seed(:os.timestamp)
    f = [&timer/3, &retry/3, &do_user_repos/3]
    |> Enum.reverse
    |> Enum.reduce(nil,
                   fn(link, acc) ->
                     fn(params, opts) ->
                       link.(acc, params, opts)
                     end
                   end)
    f.(args, options)
  end
  
end
