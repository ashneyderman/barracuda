defmodule Barracuda.Client do
  @moduledoc ~S"""
  A DSL to define a client that work with Barracuda.
  
  It provides a set of macros to generate call chains. For example:
  
      defmodule GithubClient do
        use Barracuda.Client, adapter: Barracuda.Adapter.HTTP,
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
          
        call :delete, Barracuda.Adapter.RPC,
          required: [:first_name, :last_name, :email]
      end
  """

  defmacro __using__(opts) do
    quote do
      use Barracuda.Builder, unquote(opts)
      
      Module.register_attribute __MODULE__, :otp_app, []
      @otp_app unquote(opts)[:otp_app] || raise "client expects :otp_app to be given"
      Module.register_attribute __MODULE__, :adapter, []
      @adapter unquote(opts)[:adapter]
      
      Module.register_attribute __MODULE__, :calls, accumulate: true
      import unquote(__MODULE__), only: [call: 2, call: 3]
      import Barracuda.Builder, only: [interceptor: 1, interceptor: 2]
      import Barracuda.Call
      @before_compile unquote(__MODULE__)
    end
  end
  
  defmacro __before_compile__(env) do
    calls = Module.get_attribute(env.module, :calls)
    interceptors = Module.get_attribute(env.module, :interceptors)
    otp_app = Module.get_attribute(env.module, :otp_app)
    global_adapter = Module.get_attribute(env.module, :adapter)
    for call <- calls do
      case call do
        {action, options, caller_line} ->
          define_action(action, global_adapter, options, Enum.count(interceptors), {otp_app, env.module}, caller_line)
        {action, adapter, options, caller_line} ->
          define_action(action, adapter, options, Enum.count(interceptors), {otp_app, env.module}, caller_line)
      end
    end
  end
  
  defmacro call(name, options) do
    quote bind_quoted: [name: name, options: options, caller_line: __CALLER__.line] do
      @calls {name, options, caller_line}
    end
  end
  
  defmacro call(name, adapter, options) do
    quote bind_quoted: [name: name, adapter: adapter, options: options, caller_line: __CALLER__.line] do
      @calls {name, adapter, options, caller_line}
    end
  end
  
  defp define_action(name, adapter, options, chain_size, {_, module} = config, caller_line) do
    link_name = :"__link_#{chain_size}__"
    name! = :"#{name}!"
    
    has_required = Keyword.has_key?(options, :required)
    define_docs(module, name,  adapter, options, 1, caller_line)
    define_docs(module, name!, adapter, options, 1, caller_line)

    quote do
      if unquote(has_required) do
        def unquote(name)(args) do
          unquote(link_name)(%Barracuda.Call{ args: args,
                                              adapter: unquote(adapter),
                                              options: unquote(options),
                                              config: unquote(config),
                                              action: unquote(name) }, unquote(name))
        end
        def unquote(name!)(args) do
          unquote(link_name)(%Barracuda.Call{ args: args,
                                              adapter: unquote(adapter),
                                              options: unquote(options),
                                              config: unquote(config),
                                              action: unquote(name!)  }, unquote(name!))
        end
      else
        def unquote(name)(args \\ []) do
          unquote(link_name)(%Barracuda.Call{ args: args,
                                              adapter: unquote(adapter),
                                              options: unquote(options),
                                              config: unquote(config),
                                              action: unquote(name)  }, unquote(name))
        end
        def unquote(name!)(args \\ []) do
          unquote(link_name)(%Barracuda.Call{ args: args,
                                              adapter: unquote(adapter),
                                              options: unquote(options),
                                              config: unquote(config),
                                              action: unquote(name!)  }, unquote(name!))
        end
      end
    end
  end

  defp define_docs(module, name, adapter, options, arity, caller_line) do
    docs = apply(adapter, :docs, [options, name])
    args = [{:\\, [line: caller_line], [{:options, [line: caller_line], nil}, []]}]
    Module.add_doc(module, caller_line, :def, {name, arity}, args, docs)
  end

end
