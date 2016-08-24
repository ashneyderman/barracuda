defmodule Barracuda.Error do
  defexception [:message]

  def exception(value) do
    msg = "#{ value.message }\n****\n#{ inspect value.data }\n****"
    %__MODULE__{message: msg}
  end

end
