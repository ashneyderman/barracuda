defmodule Barracuda.TestClient do
  use Barracuda.Client

  do_before :hello, [test: 123, ham: "rrerere"]
  # --->
  do_after :hello, [test: 123, ham: "rrerere"]
  
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
