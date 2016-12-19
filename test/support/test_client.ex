defmodule Barracuda.TestClient.Hello1 do
  @behaviour Barracuda.Client.Interceptor

  def init(opts), do: opts
  def link(next, call) do
    IO.puts "Barracuda.TestClient.Hello1: #{inspect call}"
    next.(call)
  end
end

defmodule Barracuda.TestClient.Hello2 do
  @behaviour Barracuda.Client.Interceptor

  def init(opts), do: opts
  def link(next, call) do
    IO.puts "Barracuda.TestClient.Hello2: #{inspect call}"
    next.(call)
  end
end

defmodule Barracuda.TestClient do
  use Barracuda.Client
  
  interceptor :hello
  interceptor Barracuda.TestClient.Hello1
  interceptor Barracuda.TestClient.Hello2

  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200

  def hello(next, call) do
    IO.puts "hello: #{inspect call}"
    next.(call)
  end

end
