defmodule Barracuda.Timer do
  @behaviour Barracuda.Client.Interceptor
  require Logger
  
  def init(opts), do: opts
  
  def link(next, %Barracuda.Client.Call{ action: action } = call) do
    {time, result} = :timer.tc(fn ->
      next.(call)
    end)
    Logger.info("#{action}: #{time} us")
    result
  end
  
end
