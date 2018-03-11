defmodule Excoverage.Settings do
@moduledoc """
Module provides application settings
"""

  @args [
    help: :boolean,
    all: :boolean,
    function: :boolean,
    line: :boolean,
    branch: :boolean,
    include_folders: :string,
    ignore_files: :string,
    detailed_report: :boolean,
    general_report: :boolena,
    test_folders: :string
  ]

  @aliases [
    h: :help,
    f: :function,
    l: :line,
    b: :branch,
    i: :include_folders,
    if: :ignore_files,
    d: :detailed_report,
    g: :general_report,
    t: :test_folders
  ]

  @type t :: %__MODULE__ {
    help: boolean,
    ignore_files: list(),
    include_folders: list(),
    mode: list(),
    reports: list(),
    test_folders: list()
  }
  defstruct help: false,
            ignore_files: [],
            include_folders: [],
            mode: [],
            reports: [:general],
            test_folders: []

  @doc """
  Parse provided arguments
  """
  @spec parse_args(argv :: [binary()]) ::
    {:ok, keyword()} | {:error, [{String.t(), String.t() | nil}]}
  def parse_args(argv) do
    IO.inspect argv
    IO.inspect argv[:include_folders]
    case OptionParser.parse(argv, strict: @args, aliases: @aliases) do
      {opts, _, []} -> IO.inspect(opts)
                       {:ok, opts}
      {_, _, issues} -> {:error, issues}
    end
  end

  @doc """
  Validate parsed arguments
  """
  @spec validate_opts(opts :: keyword())
    :: {:ok, %__MODULE__{} | {:error, []}}
  def validate_opts(opts) do
    {
      :ok, %__MODULE__{
        help: opts[:help],
        ignore_files: split_argument(opts[:ignore_files]),
        include_folders: split_argument(opts[:include_folders], ["lib"]),
        mode: get_modes(opts),
        reports: get_reports(opts),
        test_folders: split_argument(opts[:test_folders], ["test"])
      }
    }
  end

  @spec get_modes(opts :: keyword()) :: [atom()]
  defp get_modes(opts) do
    if(opts[:all]) do
      [:line, :branch, :function]
    else
      if !opts[:line] &&  !opts[:branch] && !opts[:function] do
        [:function]
      else
        Keyword.take(opts, [:line, :branch, :function])
        |> parse_param_set()
      end
    end
  end

  @spec get_reports(opts :: keyword()) :: [atom()]
  defp get_reports(opts) do
    if(!opts[:general_report] && !opts[:detailed_report]) do
      [:general_report]
    else
      Keyword.take(opts, [:general_report, :detailed_report])
      |> parse_param_set()
    end
  end

  @spec parse_param_set(opts :: keyword()) :: [atom()]
  defp parse_param_set(opts) do
    Enum.reduce(opts,[], fn({key, value}, acc) ->
      if value do
        [key | acc]
      else
        acc
      end
    end)
  end

  @spec split_argument(argument :: String.t, defaul_value :: list()) :: list()
  defp split_argument(argument, default_value \\ [])
  defp split_argument(:nil, default_value) do
    default_value
  end

  @spec split_argument(argument :: String.t, defaul_value :: list()) :: list()
  defp split_argument(argument, _default_value) do
    IO.inspect argument
    String.split(argument, " ")
  end
end
