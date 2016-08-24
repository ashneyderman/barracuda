# Barracuda

Is a library that allows generation of HTTP clients in a declarative manner. For
example,

```elixir
defmodule Github do
  use Barracuda.Compiler, otp_app: :barracuda
  require Logger
  
  call :user_repos,
    path: "/users/{:username}/repos",
    verb: :get,
    required: [:username],
    required_headers: ["accept"],
    expect: 200

end
```

is github client that will fetch user's repositories and can be used as so:

```elixir
Github.user_repos username: "ashneyderman"
```

this client needs additional configuration. Since client is part of :barracuda
application, config for it might look like this:

```elixir
config :barracuda, Github,
  base_url: "https://api.github.com"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `barracuda` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:barracuda, "~> 0.1.0"}]
    end
    ```

  2. Ensure `barracuda` is started before your application:

    ```elixir
    def application do
      [applications: [:barracuda]]
    end
    ```
