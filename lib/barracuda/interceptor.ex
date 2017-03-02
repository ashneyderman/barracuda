defmodule Barracuda.Interceptor do
  @moduledoc ~S"""
  Interface that all interceptors have to implement to be plugged into an
  interception chain as links.
  """
  
  @doc ~S"""
  Optional callback that an interceptor can specify to process interceptor
  options at compile time.
  """
  @callback init(Keyword.t) :: Keyword.t
  
  @doc ~S"""
  Required callback that gets invoked
  """
  @callback link(fun, Barracuda.Client.Call.t) :: term
  
  @optional_callbacks init: 1
end
