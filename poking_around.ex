defmodule T do
  defmacro chain(list) do
    #IO.puts "list: #{inspect list}"
    start = quote do
      fn(params) ->
        IO.puts "params: #{inspect params}"
      end
    end
    q = list |> Enum.reduce(start, fn(action, next) ->
      #IO.puts "action: #{inspect action}"
      #IO.puts "next: #{inspect next}"
      IO.puts "#{__CALLER__.module}"
      quote bind_quoted: [module: __CALLER__.module, action: Macro.escape(action), next: Macro.escape(next)] do
        fn(params) ->
          apply(module, action, [unquote(next), params])
        end
      end
    end)
    IO.inspect "q: #{Macro.to_string(q)}"
    q
  end
end

defmodule T0 do
  require T

  def timer(next, params) do
    IO.puts "timer: #{inspect params}"
    next.(params)
  end
  
  def retry(next, params) do
    IO.puts "retry - next: #{inspect next}"
    IO.puts "retry - params: #{inspect params}"
    next.(params)
  end
  
  def user_repos(params) do
    x = T.chain([:timer, :retry])
    x.(params)
  end

end


defmodule T do
  
  defmacro __using__(opts) do
    interceptors = opts |> Keyword.get(:interceptors, [])
    
    {_, quoted} = interceptors
         |> Enum.reduce({Enum.count(interceptors), []}, fn(interceptor, {n, acc}) ->
              action = interceptor
              idx = n
              pname = String.to_atom("__chain#{idx-1}")
              fname = String.to_atom("__chain#{idx}")
              {n - 1, [quote do
                def unquote(fname)(params, action) do
                  unquote(action)(
                    fn(p) ->
                      unquote(pname)(p, action)
                    end, params)
                end
              end | acc]}
            end)
    quoted
  end

end

# for interceptor <- interceptors do
#   pname = String.to_atom("__chain#{n-1}")
#   fname = String.to_atom("__chain#{n}")
#   idx = n
#   # module = __CALLER__.module
#   # action = quote do: action
#   quote do
#     def unquote(fname)(params, action) do
#       chain_logger(
#         fn(p) ->
#           unquote(pname)(p, action)
#         end, params, unquote(idx))
#     end
#   end
# end

defmodule T0 do
  use T, [interceptors: [:timer, :retry]]
  
  def retry(next, params) do
    IO.puts "retry: #{inspect params}"
    next.(params)
  end

  def timer(next, params) do
    IO.puts "timer: #{inspect params}"
    next.(params)
  end
  
  def __chain0(params, action) do
    IO.puts "action: #{inspect action}"
    IO.puts "params: #{inspect params}"
    params
  end
  
  def user_repos(params) do
    __chain2(params, :user_repos)
  end

  # def chain_logger(f, params, idx) do
  #   IO.puts "chain_logger - params:  #{inspect params}"
  #   IO.puts "chain_logger - idx:     #{idx}"
  #   f.(params)
  # end
  
end


def __chain0(params, action) do
  IO.puts "__chain0: #{inspect action}"
end

def __chain1(params, action) do
  chain_logger(fn(p) ->
          __chain0(p, action)
        end, params)
end

def __chain2(params, action) do
  chain_logger(
    fn(p) ->
      __chain1(p, action)
    end, params)
end

def user_repos(params) do
  :random.seed(:os.timestamp)
  __chain2(params, :do_user_repos)
end
