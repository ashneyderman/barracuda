defmodule Barracuda.TestClient.Hello1 do
  @behaviour Barracuda.Client.Interceptor
  import Barracuda.Client.Call

  def init(opts), do: opts
  def link(next, %Barracuda.Client.Call{assigns: current} = params) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end

  defp record_chain(current), do: current ++ ["Barracuda.TestClient.Hello1"]
end

defmodule Barracuda.TestClient.Hello2 do
  @behaviour Barracuda.Client.Interceptor
  import Barracuda.Client.Call

  def init(opts), do: opts
  def link(next, %Barracuda.Client.Call{assigns: current} = params) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end

  defp record_chain(current), do: current ++ ["Barracuda.TestClient.Hello2"]
end

defmodule Barracuda.TestClient.Adapter do
  import Barracuda.Client.Call

  def call(%Barracuda.Client.Call{assigns: current}=params, action) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, []), action))
  end

  defp record_chain(current, action), do: current ++ ["Barracuda.TestClient.Adapter.#{action}"]
end

defmodule Barracuda.TestClient.Adapter1 do
  import Barracuda.Client.Call

  def call(%Barracuda.Client.Call{assigns: current}=params, action) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, []), action))
  end

  defp record_chain(current, action), do: current ++ ["Barracuda.TestClient.Adapter1.#{action}"]
end

defmodule Barracuda.TestClient do
  use Barracuda.Client, adapter: Barracuda.TestClient.Adapter
  import Barracuda.Client.Call

  interceptor :hello
  interceptor Barracuda.TestClient.Hello1
  interceptor Barracuda.TestClient.Hello2

  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200
    
  call :no_required, Barracuda.TestClient.Adapter1,
    path: "/users/{:username}/repos",
    verb: :get,
    required_headers: ["accept"],
    expect: 200

  defp record_chain(current), do: current ++ ["hello"]

  def hello(next, %Barracuda.Client.Call{assigns: current} = params) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end
end
