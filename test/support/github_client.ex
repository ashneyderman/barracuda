defmodule Github do
  @moduledoc """
  Github client.
  """
  use Barracuda.Client, adapter: Barracuda.Adapter.HTTP,
                        otp_app: :barracuda

  interceptor Barracuda.Timer
  
  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    doc: ~S"""
    Lists all repos for the user
    """,
    expect: 200

end
