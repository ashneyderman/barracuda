defmodule Barracuda.HttpWrapper do
  require Logger
  use HTTPoison.Base
  alias HTTPoison.Response
  
  defp config({app, module}),
    do: Application.get_env(app, module, [])
    
  defp is_json_response(%Response{headers: headers}) do
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
    if is_json_response(resp) do
      Poison.decode!(resp.body)
    else
      resp
    end
  end
  
  def do_get(path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {url,     rest_args1} = construct_absolute_url(cfg, path, options, rest_args0)
    Logger.debug """
    do_get: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expect = Keyword.get(options, :expect, 200)
    case get(url, headers, options) do
      {:ok, %Response{ status_code: expect } = resp} ->
        wfn = Keyword.get(options, :response_handler, &default_response_wrapper/1)
        wfn.(resp)
      error -> error
    end
  end
  
  def do_get!(path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {url,     rest_args1} = construct_absolute_url(cfg, path, options, rest_args0)
    Logger.debug """
    do_get!: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expect = Keyword.get(options, :expect, 200)
    case get!(url, headers, options) do
      {:ok, %Response{ status_code: expect } = resp} ->
        wfn = Keyword.get(options, :response_handler, &default_response_wrapper/1)
        wfn.(resp)
      error -> error
    end
  end

  def do_post(path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {url,     rest_args1} = construct_absolute_url(cfg, path, options, rest_args0)
    body                  = construct_body(options, rest_args1)
    Logger.debug """
    do_post: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expect = Keyword.get(options, :expect, 200)
    case post(url, body, headers, options) do
      {:ok, %Response{ status_code: expect } = resp} ->
        wfn = Keyword.get(options, :response_handler, &default_response_wrapper/1)
        wfn.(resp)
      error -> error
    end
  end
  
  def do_post!(path, options, args, location) do
    cfg = config(location)
    {headers, rest_args0} = construct_headers(cfg, options, args)
    {url,     rest_args1} = construct_absolute_url(cfg, path, options, rest_args0)
    body                  = construct_body(options, rest_args1)
    Logger.debug """
    do_post!: #{inspect path}
      #{inspect options, pretty: true}
      #{inspect args, pretty: true}
      #{inspect cfg, pretty: true}
      #{inspect url}
      #{inspect headers, pretty: true}
    """
    expect = Keyword.get(options, :expect, 200)
    case post!(url, body, headers, options) do
      %Response{ status_code: expect } = resp ->
        wfn = Keyword.get(options, :response_handler, fn(r) -> r end)
        wfn.(resp)
      resp ->
        {:error, resp}
    end
  end
  
  defp construct_absolute_url(cfg, path, options, args) do
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
  
  defp construct_body(options, args), do: ""

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
