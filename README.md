Build Status
========

[![Build Status](https://semaphoreci.com/api/v1/ashneyderman/barracuda/branches/master/badge.svg)](https://semaphoreci.com/ashneyderman/barracuda)

# Barracuda

Barracuda is to your http client what [Plug](https://github.com/elixir-lang/plug) is to your web services.

For backend processing of HTTP requests we got [Plug](https://github.com/elixir-lang/plug).
There does not seem to be anything similar to write clients that access RESTful resources.
We have plenty of http clients but they all work in different ways and there is no simple
way of applying cross-cutting logic in a uniform manner to any/all of them.

Barracuda is a library that offers an easy way to generate RESTful clients for a service and easily apply cross-cutting logic.

```elixir
defmodule Github do
  @moduledoc """
  Github client.
  """
  use Barracuda.Client, adapter: Barracuda.Http.Adapter,
                        otp_app: :barracuda
  require Logger
  
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
      [{:barracuda, "~> 0.4.0"}]
    end
    ```

  2. Ensure `barracuda` is started before your application:

    ```elixir
    def application do
      [applications: [:barracuda]]
    end
    ```
    
## Acknowledgements

The original idea and draft implementation is due to [Kevin Montuori](https://github.com/kevinmontuori)
