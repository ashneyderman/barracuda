defmodule Barracuda.Builder do
  require Logger
  
  defmacro __using__(opts) do
    quote do
      @builder_opts unquote(opts)
      import Barracuda.Builder, only: [do_before: 1, do_before: 2,
                                       do_after: 1, do_after: 2]

      Module.register_attribute(__MODULE__, :before_call, accumulate: true)
      Module.register_attribute(__MODULE__, :after_call, accumulate: true)
      @before_compile Barracuda.Builder
    end
  end
  
  defmacro __before_compile__(env) do
    builder_opts = Module.get_attribute(env.module, :builder_opts)
    befores = Module.get_attribute(env.module, :before_call)
    {bcall, before_body} = Barracuda.Builder.compile_chain(env, befores, builder_opts)

    afters = Module.get_attribute(env.module, :after_call)
    {acall, after_body} = Barracuda.Builder.compile_chain(env, afters, builder_opts)

    quote do
      def before_chain(unquote(bcall)), do: unquote(before_body)
      def after_chain(unquote(acall)), do: unquote(after_body)
    end
  end
  
  defmacro do_before(link, opts \\ []) do
    quote do
      @before_call { unquote(link), unquote(opts), true }
    end
  end

  defmacro do_after(link, opts \\ []) do
    quote do
      @after_call { unquote(link), unquote(opts), true }
    end
  end
  
  def compile_chain(env, chain, builder_opts) do
    conn = quote do: conn
    {conn, Enum.reduce(chain, conn, &quote_link(init_link(&1), &2, env, builder_opts))}
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

    if function_exported?(link, :call, 2) do
      {:module, link, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect link} link must implement call/2"
    end
  end

  defp init_fun_link(link, opts, guards) do
    {:function, link, opts, guards}
  end

  defp quote_link({link_type, link, opts, guards}, acc, env, builder_opts) do
    call = quote_link_call(link_type, link, opts)

    error_message = case link_type do
      :module   -> "expected #{inspect link}.call/2 to return a Barracuda.Client.Call"
      :function -> "expected #{link}/2 to return a Barracuda.Client.Call"
    end <> ", all plugs must receive a call (Barracuda.Client.Call) and return a call"

    {fun, meta, [arg, [do: clauses]]} =
      quote do
        case unquote(compile_guards(call, guards)) do
          %Barracuda.Client.Call{halted: true} = call ->
            unquote(log_halt(link_type, link, env, builder_opts))
            call
          %Barracuda.Client.Call{} = call ->
            unquote(acc)
          _ ->
            raise unquote(error_message)
        end
      end

    generated? = :erlang.system_info(:otp_release) >= '19'

    clauses =
      Enum.map(clauses, fn {:->, meta, args} ->
        if generated? do
          {:->, [generated: true] ++ meta, args}
        else
          {:->, Keyword.put(meta, :line, -1), args}
        end
      end)

    {fun, meta, [arg, [do: clauses]]}
  end

  defp quote_link_call(:function, link, opts) do
    quote do: unquote(link)(conn, unquote(Macro.escape(opts)))
  end

  defp quote_link_call(:module, link, opts) do
    quote do: unquote(link).call(conn, unquote(Macro.escape(opts)))
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> conn
      end
    end
  end

  defp log_halt(link_type, link, env, builder_opts) do
    if level = builder_opts[:log_on_halt] do
      message = case link_type do
        :module   -> "#{inspect env.module} halted in #{inspect link}.call/2"
        :function -> "#{inspect env.module} halted in #{inspect link}/2"
      end

      quote do
        require Logger
        # Matching, to make Dialyzer happy on code executing Barracuda.Builder.compile_chain/3
        _ = Logger.unquote(level)(unquote(message))
      end
    else
      nil
    end
  end
  
end
