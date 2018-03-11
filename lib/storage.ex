defmodule Excoverage.Storage do
  @moduledoc """
  Helper module for handling storing information about covered items.
  """

  @doc """
  Initializate table
  """
  @spec init() :: :ok
  def init() do
    if :ets.info(:function_registry) == :undefined do
      :ets.new(:function_registry, [:named_table, :public])
    end
    :ok
  end

  @doc """
  Provides register ast to compile inside function content
  """
  @spec get_register_ast(key :: String.t(), register_call_line_no :: integer) :: :ok
  def get_register_ast(key, register_call_line_no) do
    {{:., [line: register_call_line_no], [:ets, :update_element]},
     [line: register_call_line_no], [:function_registry, key, {4, 1}]}
  end

  @doc """
  Register element to be checked
  """
  @spec register(
    {
      key :: String.t(),
      module_name :: String.t(),
      file_name :: String.t()
    }
  ) :: :ok
  def register({key, module_name, file_name}) do
    :ets.insert(:function_registry, {key, module_name, file_name, 0})
    :ok
  end

  @doc """
  Resets all entry states
  """
  @spec reset() :: :ok
  def reset() do
    :ets.first(:function_registry)
    |> reset
  end

  @spec reset(:"$end_of_table") :: :ok
  defp reset(:"$end_of_table"), do: :ok

  @spec reset(key :: String.t()) :: :ok
  defp reset(key) do
    :ets.update_element(:function_registry, key, {4, 0})

    :ets.next(:function_registry, key)
    |> reset
  end

  @doc """
  Register element to be checked in
  """
  @spec check(key :: String.t()) :: :ok
  def check(key) do
    :ets.update_element(:function_registry, key, {4, 1})
    :ok
  end

  @doc """
  Retrieves table content
  """
  @spec get_table_content() :: list()
  def get_table_content() do
    :ets.tab2list(:function_registry)
    |> Enum.map(fn {fun, module, file, checked} ->
      {{fun, module, file}, checked}
    end)
  end

  @doc """
  Cleanup table
  """
  @spec cleanup() :: :ok
  def cleanup() do
    if :ets.info(:function_registry) != :undefined do
      :ets.delete(:function_registry, [:named_table, :public])
    end
    :ok
  end

  @doc """
  Removes key from table
  """
  @spec remove(key :: String.t()) :: :ok
  def remove(key) do
    :ets.delete(:function_registry, key)
  end
end
