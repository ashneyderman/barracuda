defmodule Barracuda.Adapter.RPC do
  require Logger
  
  def call(%Barracuda.Call{}, _action) do
    raise RuntimeError, message: "Not yet implemented!"
  end
  
end
