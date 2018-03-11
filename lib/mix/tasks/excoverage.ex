defmodule Mix.Tasks.Excoverage do
  @moduledoc """
  Helper module for mix task
  """

  @doc """
  Runs a process from mix task
  """
  @spec run(argv :: [binary()]) :: :ok
  def run(argv) do
    Excoverage.main([{:mix_task, true} | argv])
  end
end
