defmodule Barracuda.Adapter.VCR do
  require Logger
  
  def call(%Barracuda.Call{}, _action) do
    raise RuntimeError, message: "Not yet implemented!"
  end
  
end

defmodule Barracuda.Adapter.VCRRecorder do
  @behaviour Barracuda.Interceptor
  require Logger
  
  def init(opts), do: opts
  
  def link(next, %Barracuda.Call{} = call, _opts) do
    result = next.(call)
    record(call, result)
    result
  end
  
  defp record(_call, _result) do
  end
  
end
