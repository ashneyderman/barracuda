defmodule Barracuda.Client.Call do
  @type assigns :: %{atom => any}
  
  @type t :: %__MODULE__{
    adapter: atom,
    options: Keyword.t,
    args:    Keyword.t,
    assigns: assigns
  }
  
  defstruct adapter:  nil,
            options:  [],
            args:     [],
            config:   nil,
            response: nil,
            assigns:  %{}
      
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
        use Barracuda.Client, adapter: Barracuda.Http.Adapter,
                              otp_app: :app
  
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
          
        call :delete, Barracuda.RPC.Adapter,
          required: [:first_name, :last_name, :email]
      end
  """

  defmacro __using__(opts) do
    quote do
      use Barracuda.Builder, unquote(opts)
      
      Module.register_attribute __MODULE__, :otp_app, []
      @otp_app unquote(opts)[:otp_app] || raise "client expects :otp_app to be given"
      
      Module.register_attribute __MODULE__, :calls, accumulate: true
      import unquote(__MODULE__), only: [call: 2, call: 3]
      import Barracuda.Builder, only: [interceptor: 1, interceptor: 2]
      import Barracuda.Client.Call
      @before_compile unquote(__MODULE__)
    end
  end
  
  defmacro __before_compile__(env) do
    calls = Module.get_attribute(env.module, :calls)
    interceptors = Module.get_attribute(env.module, :interceptors)
    for call <- calls do
      case call do
        {action, options} ->
          define_action(action, options, Enum.count(interceptors), {Module.get_attribute(env.module, :otp_app), env.module})
        {action, adapter, options} ->
          define_action(action, adapter, options, Enum.count(interceptors), {Module.get_attribute(env.module, :otp_app), env.module})
      end
    end
  end
  
  defmacro call(name, options) do
    quote bind_quoted: [name: name, options: options] do
      @calls {name, options}
    end
  end
  
  defmacro call(name, adapter, options) do
    quote bind_quoted: [name: name, adapter: adapter, options: options] do
      @calls {name, adapter, options}
    end
  end
  
  defp define_action(name, adapter, options, chain_size, config) do
    link_name = :"__link_#{chain_size}__"
    name! = :"#{name}!"

    q0 = quote do
      def unquote(name)(args) do
        unquote(link_name)(%Barracuda.Client.Call{ args: args,
                                                   adapter: unquote(adapter),
                                                   options: unquote(options),
                                                   config: unquote(config) }, unquote(name))
      end
      def unquote(name!)(args) do
        unquote(link_name)(%Barracuda.Client.Call{ args: args,
                                                   adapter: unquote(adapter),
                                                   options: unquote(options),
                                                   config: unquote(config) }, unquote(name!))
      end
    end
    
    if !Keyword.has_key?(options, :required) do
      q1 = quote do
        def unquote(name)() do
          unquote(link_name)(%Barracuda.Client.Call{ args: [],
                                                     adapter: unquote(adapter),
                                                     options: unquote(options),
                                                     config: unquote(config) }, unquote(name))
        end
        def unquote(name!)() do
          unquote(link_name)(%Barracuda.Client.Call{ args: [],
                                                     adapter: unquote(adapter),
                                                     options: unquote(options),
                                                     config: unquote(config) }, unquote(name!))
        end
      end
      [q0,q1]
    else
      q0
    end
  end

  defp define_action(name, options, chain_size, config) do
    link_name = :"__link_#{chain_size}__"
    name! = :"#{name}!"

    q0 = quote do
      def unquote(name)(args) do
        unquote(link_name)(%Barracuda.Client.Call{ args: args,
                                                   options: unquote(options),
                                                   config: unquote(config) }, unquote(name))
      end
      def unquote(name!)(args) do
        unquote(link_name)(%Barracuda.Client.Call{ args: args,
                                                   options: unquote(options),
                                                   config: unquote(config) }, unquote(name!))
      end
    end
    
    if !Keyword.has_key?(options, :required) do
      q1 = quote do
        def unquote(name)() do
          unquote(link_name)(%Barracuda.Client.Call{ args: [],
                                                     options: unquote(options),
                                                     config: unquote(config) }, unquote(name))
        end
        def unquote(name!)() do
          unquote(link_name)(%Barracuda.Client.Call{ args: [],
                                                     options: unquote(options),
                                                     config: unquote(config) }, unquote(name!))
        end
      end
      [q0,q1]
    else
      q0
    end
  end

end
