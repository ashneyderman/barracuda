defmodule Barracuda.Timer do
  @behaviour Barracuda.Interceptor
  require Logger
  
  def init(opts), do: opts
  
  def link(next, %Barracuda.Call{ action: action } = call, opts \\ []) do
    {time, result} = :timer.tc(fn ->
      next.(call)
    end)
    Logger.info("#{action}: #{time} us [opts: #{inspect opts}]")
    result
  end
  
end
