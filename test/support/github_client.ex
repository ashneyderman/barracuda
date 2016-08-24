defmodule ResponseHandlers do
  require Logger
  alias HTTPoison.Response

  def auth_resp(%Response{ status_code: 200, headers: headers }),
    do: Enum.into(headers, %{}) |> Dict.get("authorization")
  
end

defmodule GithubClient do
  use Barracuda.Compiler, otp_app: :barracuda
  require Logger
  
  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200

end
