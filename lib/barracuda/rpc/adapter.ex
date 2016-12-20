defmodule Barracuda.RPC.Adapter do
  require Logger
  
  def call(%Barracuda.Client.Call{}, _action) do
    raise RuntimeError, message: "Not yet implemented!"
  end
  
end
