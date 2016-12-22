defmodule Barracuda.Http.Adapter do
  require Logger
  use HTTPoison.Base
  alias HTTPoison.Response
  
  def call(%Barracuda.Client.Call{ options: options, args: args, config: config } = call, action) do
    path = Keyword.fetch!(options, :path)
    response = apply(__MODULE__, local_method(options, action), [path, options, args, config])
    %Barracuda.Client.Call{ call | response: response }
  end
  
  defp local_method(options, action) do
    verb = options |> Keyword.get(:verb)
    if String.ends_with?(Atom.to_string(action), "!"),
      do: :"do_#{Atom.to_string(verb)}!",
    else: :"do_#{Atom.to_string(verb)}"
  end
  
  def do_get(path, options, args, location),
    do: do_request(:get, path, options, args, location)
  
  def do_get!(path, options, args, location),
    do: do_request!(:get, path, options, args, location)
  
  def do_post(path, options, args, location),
    do: do_request(:post, path, options, args, location)
  
  def do_post!(path, options, args, location),
    do: do_request!(:post, path, options, args, location)
  
  def do_put(path, options, args, location),
    do: do_request(:put, path, options, args, location)
  
  def do_put!(path, options, args, location),
    do: do_request!(:put, path, options, args, location)
  
  def do_delete(path, options, args, location),
    do: do_request(:delete, path, options, args, location)
  
  def do_delete!(path, options, args, location),
    do: do_request!(:delete, path, options, args, location)
  
  defp do_request(method, path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {body,    rest_args1} = construct_body(headers, options, rest_args0)
    {url,     _rest_args2} = construct_absolute_url(cfg, path, options, rest_args1)
    Logger.debug """
    #{inspect method}: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expected = Keyword.get(options, :expect, 200)
    case apply(__MODULE__, :request, [method, url, body, headers, options]) do
      {:ok, %Response{ status_code: status_code } = resp} when status_code == expected ->
        wfn = Keyword.get(options, :response_handler, &default_response_wrapper/1)
        wfn.(resp)
      {:ok, %Response{ status_code: status_code } = resp} when status_code != expected ->
        {:error, resp}
      error ->
        error
    end
  end
  
  defp do_request!(method, path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {body,    rest_args1} = construct_body(headers, options, rest_args0)
    {url,     _rest_args2} = construct_absolute_url(cfg, path, options, rest_args1)
    Logger.debug """
    #{inspect method}: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expected = Keyword.get(options, :expect, 200)
    case apply(__MODULE__, :request, [method, url, body, headers, options]) do
      {:ok, %Response{ status_code: status_code } = resp}  when status_code == expected ->
        wfn = Keyword.get(options, :response_handler, &default_response_wrapper/1)
        case wfn.(resp) do
          {:ok, result} ->
            result
          {:error, error} ->
            raise(Barracuda.Error, %{ message: "HTTP call resulted in error", data: error })
        end
      {:ok, %Response{ status_code: status_code } = resp}  when status_code != expected ->
        raise(Barracuda.Error, %{ message: "HTTP call resulted in unexpected status code. Expected: #{expected}; Returned: #{status_code}", data: resp })
      other ->
        raise(Barracuda.Error, %{ message: "HTTP call resulted in error response.", data: other })
    end
  end
  
  defp config({app, module}), do: Application.get_env(app, module, [])
  
  defp is_json(%Response{headers: headers}), do: is_json(headers)
  defp is_json(headers) do
    Logger.debug "headers: #{inspect headers, pretty: true}"
    headers_map = headers |> Enum.into(HashDict.new)
    key = headers_map
          |> Dict.keys
          |> Enum.find(nil, &(String.downcase(&1) == "content-type"))
  
    if key do
      headers_map
      |> Dict.get(key, "")
      |> String.downcase
      |> String.starts_with?(["application/json"])
    else
      false
    end
  end
  
  defp default_response_wrapper(%Response{}=resp) do
    if is_json(resp) do
      Poison.decode(resp.body)
    else
      {:ok, resp}
    end
  end
  
  defp construct_absolute_url(cfg, path, _options, args) do
    base_url = Keyword.get(cfg, :base_url)
    {interpolated_path, remaining_args} = interpolate_path(path, args, true)
    {base_url <> interpolated_path, remaining_args}
  end
  
  defp construct_headers(cfg, options, args) do
    required_headers = Keyword.get(options, :required_headers, [])
    required_headers |> Enum.reduce({[], args}, fn(key, {headers, arguments}) ->
      atom_key = String.to_atom(key)
      value = Keyword.get(arguments, atom_key, Keyword.get(cfg, atom_key))
      {[{key, value} | headers], Keyword.delete(arguments, atom_key)}
    end)
  end
  
  defp construct_body(headers, _options, args) do
    if Keyword.get(args, :body, nil) do
      {args |> Keyword.get(:body, "") |> encode_body(headers),
       Keyword.delete(args, :body)}
    else
      {"", args}
    end
  end
  
  defp encode_body(body, _headers) when is_binary(body), do: body
  defp encode_body(body, headers),
    do: if is_json(headers), do: Poison.encode!(body), else: body
  
  def interpolate_path(path, nil, _), do: {path, []}
  def interpolate_path(path, args, consume_remainder) do
    {interpolated_path, remaining_args} = replace_path_parts(path, args)
    if consume_remainder do
      case URI.encode_query(remaining_args) do
        "" -> {interpolated_path, []}
        query_string ->
          if String.contains?(interpolated_path, "?") do
            {interpolated_path <> "&" <> query_string, []}
          else
            {interpolated_path <> "?" <> query_string, []}
          end
      end
    else
      {interpolated_path, remaining_args}
    end
  end
  
  # TODO - there is gotta be an agentless way to do this
  defp replace_path_parts(path, args) do
    {:ok, arguments} = Agent.start(fn -> args end)
    interpolated_path = Regex.replace(~r/({:.+?})/, path,
      fn(tag) -> key = String.slice(tag, 2..-2) |> String.to_atom
                 value = Keyword.get(args, key, tag) |> to_string
                 Agent.update(arguments, &(Keyword.delete(&1, key)))
                 value end)
    remaining_args = Agent.get(arguments, &(&1))
    Agent.stop(arguments)
    {interpolated_path, remaining_args}
  end

end
