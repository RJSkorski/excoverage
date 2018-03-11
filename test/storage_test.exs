defmodule Excoverage.Storage.Test do
  @moduledoc false

  use ExUnit.Case
  alias Excoverage.Storage

  doctest Excoverage.Storage

  setup_all do
    Storage.init()
    :ok
  end

  test "Register should add entry in :function_registry table" do
    test_entry = {"key", "module_name", "file_name"}

    Storage.register(test_entry)

    content = Storage.get_table_content()

    assert Enum.any?(content, fn {{fun, module, file}, checked} ->
             fun == "key" && module == "module_name" && file == "file_name" && checked == 0
           end)

    Storage.remove("key")
  end

  test "Remove should delete entry from :function_registry table" do
    test_entry = {"key", "module_name", "file_name"}

    Storage.register(test_entry)
    Storage.remove("key")

    content = Storage.get_table_content()

    refute Enum.any?(content, fn {{fun, module, file}, checked} ->
             fun == "key" && module == "module_name" && file == "file_name" && checked == 0
           end)
  end

  test "Check should set a checked column to 1" do
    test_entry = {"key", "module_name", "file_name"}

    Storage.register(test_entry)
    Storage.check("key")

    content = Storage.get_table_content()

    assert Enum.any?(content, fn {{fun, module, file}, checked} ->
             fun == "key" && module == "module_name" && file == "file_name" && checked == 1
           end)

    Storage.remove("key")
  end
end
