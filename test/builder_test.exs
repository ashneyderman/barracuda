defmodule Barracuda.BuilderTest.Interceptor do
  @behaviour Barracuda.Client.Interceptor

  import Barracuda.Client.Call

  def init(opts), do: opts
  def link(next, %Barracuda.Client.Call{assigns: current} = params) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end

  defp record_chain(current), do: current ++ ["Barracuda.BuilderTest.Interceptor"]

end

defmodule Barracuda.BuilderTest.Intercepted do
  use Barracuda.Builder

  interceptor Barracuda.BuilderTest.Interceptor
  interceptor :hello

  defp record_chain(current), do: current ++ ["hello"]

  def hello(next, %Barracuda.Client.Call{assigns: current} = params) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end
end

defmodule Barracuda.BuilderTest do
  use ExUnit.Case, async: true
  alias Barracuda.BuilderTest.Intercepted
  alias Barracuda.Client.Call

  test "exports __link_*__" do
    exports = Intercepted.module_info()
              |> Keyword.get(:exports)
              
    assert Keyword.get(exports, :__link_0__) == 2
    assert Keyword.get(exports, :__link_1__) == 2
    assert Keyword.get(exports, :__link_2__) == 2
    assert Keyword.get(exports, :__link_3__, nil) == nil
  end

  test "chained calls" do
    %Call{assigns: %{chain: chain}} = Intercepted.__link_2__(%Call{}, :do_something)
    assert chain == ["Barracuda.BuilderTest.Interceptor", "hello"]
  end

end
