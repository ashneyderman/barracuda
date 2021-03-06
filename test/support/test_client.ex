defmodule Barracuda.TestClient.Hello1 do
  @behaviour Barracuda.Interceptor
  import Barracuda.Call

  def init(opts), do: opts
  def link(next, %Barracuda.Call{assigns: current} = params, _opts \\ []) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end

  defp record_chain(current), do: current ++ ["Barracuda.TestClient.Hello1"]
end

defmodule Barracuda.TestClient.Hello2 do
  @behaviour Barracuda.Interceptor
  import Barracuda.Call

  def init(opts), do: opts
  def link(next, %Barracuda.Call{assigns: current} = params, _opts \\ []) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end

  defp record_chain(current), do: current ++ ["Barracuda.TestClient.Hello2"]
end

defmodule Barracuda.TestClient.Adapter do
  import Barracuda.Call

  def docs(_, _), do: "Adapter: No docs."

  def call(%Barracuda.Call{assigns: current}=params, action) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, []), action))
  end

  defp record_chain(current, action), do: current ++ ["Barracuda.TestClient.Adapter.#{action}"]
end

defmodule Barracuda.TestClient.Adapter1 do
  import Barracuda.Call

  def docs(_, _), do: "Adapter1: No docs."

  def call(%Barracuda.Call{assigns: current}=params, action) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, []), action))
  end

  defp record_chain(current, action), do: current ++ ["Barracuda.TestClient.Adapter1.#{action}"]
end

defmodule Barracuda.TestClient do
  use Barracuda.Client, adapter: Barracuda.TestClient.Adapter,
                        otp_app: :barracuda
  import Barracuda.Call

  interceptor :hello
  interceptor Barracuda.TestClient.Hello1
  interceptor Barracuda.TestClient.Hello2

  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    doc: ~S"""
    Lists all repos for the user
    """,
    expect: 200
  
  call :no_required, Barracuda.TestClient.Adapter1,
    path: "/users/ashneyderman/repos",
    verb: :get,
    required_headers: ["accept"],
    doc: ~S"""
    Lists all repos for ashneyderman
    """,
    expect: 200

  defp record_chain(current), do: current ++ ["hello"]

  def hello(next, %Barracuda.Call{assigns: current} = params, _opts \\ []) do
    params
    |> assign(:chain, record_chain(Map.get(current, :chain, [])))
    |> next.()
  end
end
