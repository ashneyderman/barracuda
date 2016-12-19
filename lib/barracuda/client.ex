defmodule Barracuda.Client.Call do
  @type assigns :: %{atom => any}
  
  @type t :: %__MODULE__{
    adapter: atom,
    options: Keyword.t,
    args:    Keyword.t,
    assigns: assigns
  }
  
  defstruct adapter: nil,
            options: [],
            args:    [],
            assigns: %{}
      
  @doc """
  Assigns a value to a key in the connection

  ## Examples

  iex> conn.assigns[:hello]
  nil
  iex> conn = assign(conn, :hello, :world)
  iex> conn.assigns[:hello]
  :world
  """
  @spec assign(t, atom, term) :: t
  def assign(%Barracuda.Client.Call{assigns: assigns} = call, key, value) when is_atom(key) do
    %{call | assigns: Map.put(assigns, key, value)}
  end
end

defmodule Barracuda.Client.Interceptor do
  @moduledoc ~S"""
  Interface that all interceptors have to implement to be plugged into an
  interception chain as links.
  """
  
  @doc ~S"""
  Optional callback that an interceptor can specify to process interceptor
  options at compile time.
  """
  @callback init(Keyword.t) :: Keyword.t
  
  @doc ~S"""
  Required callback that gets invoked
  """
  @callback link(fun, Barracuda.Client.Call.t) :: Barracuda.Client.Call.t
  
  
  @optional_callbacks init: 1
end

defmodule Barracuda.Client do
  @moduledoc ~S"""
  A DSL to define a client that work with Barracuda.
  
  It provides a set of macros to generate call chains. For example:
  
      defmodule GithubClient do
        use Barracuda.Client
  
        interceptor Barracuda.Performance
        interceptor Barracuda.Validator
        interceptor Barracuda.ResultsConverter
        
        call :create,
          path: "customers.json",
          verb: :post,
          required: [:first_name, :last_name, :email],
          container: "customer",
          expect: 201,
          api: :v1
      end
  """

  defmacro __using__(opts) do
    quote do
      def do_call(%Barracuda.Client.Call{} = call) do
        IO.puts "doing the actual call ..."
        call
      end
      
      use Barracuda.Builder, unquote(opts)
      
      Module.register_attribute __MODULE__, :calls, accumulate: true
      import unquote(__MODULE__), only: [call: 2]
      import Barracuda.Builder, only: [interceptor: 1, interceptor: 2]
      import Barracuda.Client.Call
      @before_compile unquote(__MODULE__)
    end
  end
  
  defmacro __before_compile__(env) do
    calls = Module.get_attribute(env.module, :calls)
    interceptors = Module.get_attribute(env.module, :interceptors)
    for {action, options} <- calls do
      define_action(action, options, Enum.count(interceptors))
    end
  end
  
  defmacro call(name, options) do
    quote bind_quoted: [name: name, options: options] do
      @calls {name, options}
    end
  end
  
  defp define_action(name, _options, chain_size) do
    link_name = :"__link_#{chain_size}__"
    quote do
      def unquote(name)(args) do
        unquote(link_name)(%Barracuda.Client.Call{ args: args }, unquote(name))
      end
    end
  end

end
