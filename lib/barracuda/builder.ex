defmodule Barracuda.Builder do
  @moduledoc ~S"""
  A DSL to define an interception chain.
    
  It provides macro to generate call chains. For example:
  
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
      
  will generate a call chain where call :create will be wrapped into a chain
  of the specified interceptors. Each interceptor has the ability to wrap the
  chain right below it. Upon wrapping interceptor can decide to advance the
  chain, modify parameters of the next link in the chain or modify results of
  the call to the next link on the chain.
  """
  
  require Logger
  
  defmacro __using__(opts) do
    quote do
      @builder_opts unquote(opts)
      Module.register_attribute(__MODULE__, :interceptors, accumulate: true)
      import Barracuda.Builder, only: [interceptor: 1, interceptor: 2]
      import Barracuda.Client.Call
      @before_compile Barracuda.Builder
    end
  end
  
  defp generate_terminator_link() do
    quote do
      def __link_0__(%Barracuda.Client.Call{ adapter: adapter } = call, action) do
        apply(adapter, :call, [call, action])
      end
    end
  end
  
  defmacro __before_compile__(env) do
    builder_opts = Module.get_attribute(env.module, :builder_opts)
    interceptors = Module.get_attribute(env.module, :interceptors) |> Enum.reverse
    
    [ generate_terminator_link() |
      Barracuda.Builder.compile_chain(env, interceptors, builder_opts) ]
  end
  
  defmacro interceptor(link, opts \\ []) do
    quote do
      @interceptors { unquote(link), unquote(opts), true }
    end
  end
  
  def compile_chain(_env, nil, _builder_opts), do: []
  def compile_chain(_env, [], _builder_opts),  do: []
  def compile_chain(env, links, builder_opts) do
    {_, quoted} = links
         |> Enum.map(&init_link/1)
         |> Enum.reduce({Enum.count(links), []}, fn(link, {n, acc}) ->
              {n-1, [quote_link(link, n, env, builder_opts) | acc]}
            end)
    quoted
  end
  
  # Initializes the options of a plug at compile time.
  defp init_link({link, opts, guards}) do
    case Atom.to_char_list(link) do
      ~c"Elixir." ++ _ -> init_module_link(link, opts, guards)
      _                -> init_fun_link(link, opts, guards)
    end
  end

  defp init_module_link(link, opts, guards) do
    initialized_opts = link.init(opts)

    if function_exported?(link, :link, 2) do
      {:module, link, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect link} link must implement link/2"
    end
  end

  defp init_fun_link(link, opts, guards) do
    {:function, link, opts, guards}
  end

  defp quote_link({link_type, link, _opts, _guards}, idx, _env, _builder_opts) do
    pname = String.to_atom("__link_#{idx-1}__")
    fname = String.to_atom("__link_#{idx}__")
    case link_type do
      :module ->
        quote do
          def unquote(fname)(call, action) do
            unquote(link).link(
              fn(params) ->
                unquote(pname)(params, action)
              end, call)
          end
        end
      :function ->
        quote do
          def unquote(fname)(call, action) do
            unquote(link)(
              fn(params) ->
                unquote(pname)(params, action)
              end, call)
          end
        end
    end
  end
  
end
