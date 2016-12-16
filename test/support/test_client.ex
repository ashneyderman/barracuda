defmodule Barracuda.TestClient.Hello1 do
  @behaviour Barracuda.Client.Interceptor
  
  def init(opts), do: opts
  def call(call, opts) do
    IO.puts "Barracuda.TestClient.Hello1: #{inspect call}, #{inspect opts}"
    call
  end
end

defmodule Barracuda.TestClient.Hello2 do
  @behaviour Barracuda.Client.Interceptor
  
  def init(opts), do: opts
  def call(call, opts) do
    IO.puts "Barracuda.TestClient.Hello2: #{inspect call}, #{inspect opts}"
    call
  end
end

defmodule Barracuda.TestClient do
  use Barracuda.Client

  do_before :hello, [test: 123, ham: "rrerere"]
  do_before Barracuda.TestClient.Hello1, [id: 34, name: "test"]
  # --->
  do_after  Barracuda.TestClient.Hello2, [id: 56, name: "test1"]
  do_after  :hello, [test: 123, ham: "rrerere"]
  
  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200
    
  def hello(call, opts \\ []) do
    IO.puts "hello: #{inspect call}, #{inspect opts}"
    call
  end

end
