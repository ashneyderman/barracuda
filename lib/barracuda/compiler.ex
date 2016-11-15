defmodule Barracuda.Compiler do
  require Logger

  @default_verb :get

  @moduledoc """

  The DSL used to describe the API has stanzas like

    call :create,
      path: "customers.json",
      verb: :post,
      required: [:first_name, :last_name, :email],
      container: "customer",
      expect: 201,
      api: :v1

   `create/1` will be the name of the generated function.

   The HTTP action will be a POST to the path customers.json prepended
   with the value of `base_url` from the application config.  A result
   code of 201 is required

   The :first_name, :last_name, and :email parameters must be
   specified or the request will not be generated.  These and any
   additional parameters will be JSON encoded ({"key":"value"}) and
   then wrapped inside the customer conatiner
   ({"customer":{"key":"value"}}).

   If the path has placeholders:

       call :lookup,
       path: "resource/{:type}/{:id}/",
       required: [:id, :type]

   The values specified for :id and :type will be interpolated into
   the path string.  If there is only one required parameter and only
   one placeholder then the key is optional.  For instance, the
   function generated with this stanza:

       call :lookup,
       path: "resource/{:id}",
       required: [:id]

   may be called as either `lookup(id: 123)` or `lookup(123)`.

   The :expect option defaults to :200; :verb defaults to :get. Required
   headers will be retrieved from

   In the case of the :lookup stanza, two functions are generated:

     `lookup/1` which returns `{:ok, status_code, headers, body}`
     (similar to hackney) or `{:error, msg, {options, response}}`.
     The msg might be descriptive; `options` is a keyword list
     representing the stanza as defined.  The body is decoded from the
     JSON into an atom keyed map.

     `lookup!/1` which returns only the body, decoded, upon success
     and raises Barracuda.Error otherwise.
   """
  defmacro __using__(options) do
    quote do
      Module.register_attribute __MODULE__, :otp_app, []
      @otp_app unquote(options)[:otp_app] || raise "client expects :otp_app to be given"
      
      Module.register_attribute __MODULE__, :calls, accumulate: true
      import unquote(__MODULE__), only: [call: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :calls),
            env.module,
            {Module.get_attribute(env.module, :otp_app), env.module})
  end

  defmacro call(name, options) do
    quote bind_quoted: [name: name, options: options] do
      @calls {name, options}
    end
  end

  def compile(calls, module, config) do
    for {action, options} <- calls do
      path = Keyword.fetch!(options, :path)
      verb = Keyword.get(options, :verb, @default_verb)
      line = __ENV__.line
      bang = to_string(action) <> "!"
      args = [{:\\, [line: line], [{:options, [line: line], nil}, []]}]
      doc = """
      #{ Keyword.get(options, :doc, "No documentation provided.") }
      Returns {:ok, result} or
      {:error, error}.

      Returns just the body and raises Barracuda.Error if called as #{ bang }/1.

      [#{ to_string(verb) |> String.upcase }] #{ path }
      """

      Module.add_doc(module, line, :def, {action, 1}, args, doc)

      case verb  do
        :get    -> define_action(:do_get,    action, path, options |> Keyword.put(:action, action), config)
        :post   -> define_action(:do_post,   action, path, options |> Keyword.put(:action, action), config)
        :put    -> define_action(:do_put,    action, path, options |> Keyword.put(:action, action), config)
        :delete -> define_action(:do_delete, action, path, options |> Keyword.put(:action, action), config)
        verb -> raise "Verb #{ inspect verb } not implemented."
      end
    end
  end

  defp define_action(verb, action, path, options, config) do
    q0 = quote do
      def unquote(action)(args) do
        apply(Barracuda.HttpWrapper, unquote(verb),
              [unquote(path), unquote(options), args, unquote(config)])
      end
      def unquote(String.to_atom("#{ action }!"))(args) do
        apply(Barracuda.HttpWrapper, unquote(String.to_atom("#{ to_string(verb) }!")),
              [unquote(path), unquote(options), args, unquote(config)])
      end
    end

    if !Keyword.has_key?(options, :required) do
      q1 = quote do
        def unquote(action)() do
         apply(Barracuda.HttpWrapper, unquote(verb),
               [unquote(path), unquote(options), [], unquote(config)])
        end
        def unquote(String.to_atom("#{ action }!"))() do
         apply(Barracuda.HttpWrapper, unquote(String.to_atom("#{ to_string(verb) }!")),
               [unquote(path), unquote(options), [], unquote(config)])
        end
      end
      [q0,q1]
    else
      q0
    end
  end

end
