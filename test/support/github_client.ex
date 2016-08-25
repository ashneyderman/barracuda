defmodule Github do
  @moduledoc """
  Github client.
  """
  use Barracuda.Compiler, otp_app: :barracuda
  require Logger
  
  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200

end
