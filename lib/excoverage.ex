defmodule Excoverage do
  @moduledoc """
  Helper module for parsing parameters
  """

  alias Excoverage.{Executor, Settings}

  @doc """
  Start initialization process and return function that should be run, when tests are done
  """
  @spec start(
    compilation_path :: String.t(),
    args :: [binary()]
  ) :: function
  def start(_compilation_path, args) do
    case main(args, &Executor.init_process/1) do
      {:ok, params} ->
          fn() ->
            Executor.get_results(params.reports)
          end
      {:error, nil} ->
        nil
    end
  end

  @doc """
  Runs Excoverage from both command line or mix task
  """
  @spec main(argv :: [binary()]) :: :ok
  def main(argv) do
    case Settings.parse_args(argv) do
      {:ok, opts} -> main(opts, &Executor.execute/1)
      {:error, issues} ->
        IO.puts("Wrong parameters: ") <> IO.inspect(issues)
        {:error, nil}
    end
  end

  @spec main(opts :: keyword(), func :: function) :: :ok
  defp main(opts, func) do
    case Settings.validate_opts(opts) do
    {:ok, params} ->
      process(params, func)
      {:ok, params}
    {:error, issues} ->
      IO.puts("Wrong parameters: ") <> IO.inspect(issues)
      {:error, nil}
    end
  end

  @spec process(params :: %Settings{}, func :: function) :: :ok
  defp process(params, func) do
    if params.help do
      show_help()
    else
      func.(params)
    end
  end

  @doc """
  Shows help message
  """
  @spec show_help() :: :ok
  def show_help() do
    IO.puts '''
    Usage: mix excoverage [OPTION]...
    Calculate test coverage

    List of arguments in alphabetic order:
      -a, --all               calculate test coverage in all modes (for now only function supported)
      -b, --branch            calculate test coverage for branches (not supported)
      -d, --detailed_report   generate detailed report
      -f, --function          calculate test coverage for functions (default value)
      -g, --general_report    generate general report (default value)
      -h, --help              show this message
      -i, --include_folders   folders with source code to be included (default ./lib)
      -if,--ignore_files      a list of files to be ignored (comma separated)
      -im,--igonre_modules    a list of modules to be ignored (comma separated)
      -l, --line              calculate test coverage for lines (not supported)
      -t, --test_folder       folder with tests to execute (should not be used with mix)
    '''
    :ok
  end
end
