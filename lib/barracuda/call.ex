defmodule Barracuda.Call do
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
            assigns:  %{},
            action:   nil,
            vcr_mode: false
      
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
  def assign(%Barracuda.Call{assigns: assigns} = call, key, value) when is_atom(key) do
    %{call | assigns: Map.put(assigns, key, value)}
  end
end
