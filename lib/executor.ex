defmodule Excoverage.Executor do
  @moduledoc """
  This module contains functions that handle execution flow.
  """

  alias Excoverage.{Storage, Files, CodeParser, Reporter}

  @spec init_process(args :: Excoverage.t()) :: :ok
  def init_process(args) do
    Mix.env(:test)
    Storage.init()

    Files.get_file_names(args.include_folders, args.ignore_files)
    |> CodeParser.init_files(Files, Storage)

    Storage.reset()
  end


  @doc """
  Runs the process
  """
  @spec execute(args :: Excoverage.t()) :: :ok
  def execute(args) do
    init_process(args)
    run_tests(args.test_folders)

    get_results(args.reports)

    Storage.cleanup()
    :ok
  end

  @doc """
  Retrieves coverage results
  """
  @spec get_results(report_modes :: list()) :: :ok
  def get_results(report_modes) do
    {:ok, result} = CodeParser.get_results(Storage)
    |> Reporter.generate_txt_report(report_modes)

    IO.puts(result)
    :ok
  end

  @spec run_tests(fodlers :: [String.t()]) :: map()
  defp run_tests(folders) do
    Mix.Task.run("test", folders)
  end
end
