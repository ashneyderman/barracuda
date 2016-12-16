defmodule Barracuda.Client.Call do
  @type state :: :unset | :set | :sent
  
  @type t :: %__MODULE__{
    verb:    atom,
    path:    String.t,
    options: Keyword.t,
    args:    Keyword.t,
    config:  Keyword.t,
    state:   state,
    halted:  boolean
  }
  
  defstruct verb: nil,
    path:    nil,
    options: [],
    args:    [],
    config:  [],
    state:   :unset,
    halted:  false
end

defmodule Barracuda.Client.Interceptor do
  @callback init(Keyword.t) :: Keyword.t
  @callback call(Barracuda.Client.Call.t, Keyword.t) :: Barracuda.Client.Call.t
end

defmodule Barracuda.Client do
  @moduledoc ~S"""
  A DSL to define a client that work with Barracuda.
  
  It provides a set of macros to generate call chains. For example:
  
      defmodule GithubClient do
        use Barracuda.Client
  
        do_before Barracuda.Performance
        do_before Barracuda.Validator
        
        do_after Barracuda.ResultsConverter
        do_after Barracuda.Performance
        
        call :create,
          path: "customers.json",
          verb: :post,
          required: [:first_name, :last_name, :email],
          container: "customer",
          expect: 201,
          api: :v1
      end

  ## Options
  
  When used, the following options are accepted by `Plug.Router`:
  
    * `:log_on_halt` - accepts the level to log whenever the request is halted
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
      @before_compile unquote(__MODULE__)
    end
  end
  
  defmacro __before_compile__(env) do
    calls = Module.get_attribute(env.module, :calls)
    for {action, _options} <- calls do
      define_action(action)
    end
  end
  
  defmacro call(name, options) do
    quote bind_quoted: [name: name, options: options] do
      @calls {name, options}
    end
  end
  
  defp define_action(name) do
    quote do
      def unquote(name)(args) do
        %Barracuda.Client.Call{args: args}
          |> before_chain
          |> do_call
          |> after_chain
      end
    end
  end

end
