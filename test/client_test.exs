defmodule Barracuda.ClientTest do
  use ExUnit.Case, async: true
  alias Barracuda.TestClient
  alias Barracuda.Call

  test "exports user_repos" do
    exports = TestClient.module_info(:exports)
    assert Keyword.get(exports, :user_repos) == 1
  end

  test "user_repos client call" do
    %Call{assigns: %{chain: chain}} = TestClient.user_repos([])
    assert chain == ["hello", "Barracuda.TestClient.Hello1", "Barracuda.TestClient.Hello2", "Barracuda.TestClient.Adapter.user_repos"]
  end

  test "no_required client call" do
    %Call{assigns: %{chain: chain}} = TestClient.no_required([])
    assert chain == ["hello", "Barracuda.TestClient.Hello1", "Barracuda.TestClient.Hello2", "Barracuda.TestClient.Adapter1.no_required"]
  end

  test "all client methods are exported" do
    exports = TestClient.module_info(:exports)

    assert Keyword.get(exports, :user_repos) == 1
    assert Keyword.get(exports, :user_repos!) == 1
    assert (Keyword.get_values(exports, :no_required) |> Enum.sort) == [0, 1]
    assert (Keyword.get_values(exports, :no_required!) |> Enum.sort) == [0, 1]
  end

end
