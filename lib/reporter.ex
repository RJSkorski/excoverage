defmodule Excoverage.Reporter do
  @moduledoc """
  Helper module for generating test coverage reports.
  """

  @doc """
  Generates txt coverage report
  """
  @spec generate_txt_report(
    result_map :: %{},
    report_modes :: list())
      :: {:ok, String.t()}
  def generate_txt_report(result_map, _report_modes) when result_map == %{} do
    {:ok, "No files to be examinated"}
  end

  @doc """
  Generates text report
  """
  @spec generate_txt_report(
    result_map :: map(),
    report_modes :: list())
      :: {:ok, String.t()}
  def generate_txt_report(result_map, report_modes) do
    {
      :ok, Enum.reduce(report_modes, "", fn(report_mode, acc) ->
        case report_mode do
          :general_report -> "#{acc}\n#{get_standard_report(result_map)}"
          :detailed_report -> "#{acc}\n#{get_detailed_report(result_map)}"
        end
      end)
    }
  end

  @spec get_detailed_report(result_map :: map()) :: String.t()
  defp get_detailed_report(result_map) do
    get_report(result_map, "File/Module/Function", true)
  end

  @spec get_standard_report(result_map :: map()) :: String.t()
  defp get_standard_report(result_map) do
    get_report(result_map, "File", false)
  end

  @spec get_report(
    result_map :: map(),
    header_desc :: String.t(),
    detailed :: boolean
  ) :: String.t()
  defp get_report(result_map, header_desc, detailed) do
    header = get_line("Cov", header_desc, "Checked", "All")
    {result, checked, all} = get_section_with_sum(result_map, detailed)

    footer_proc = get_procentage_representation(checked, all)
    footer = get_line(footer_proc, "Overall", checked, all)

    "#{header}#{result}\n#{footer}"
  end

  @spec get_section_with_sum(result_map :: map(), detailed :: boolean) :: String.t()
  defp get_section_with_sum(result_map, detailed) do
    Enum.reduce(result_map, {"", 0, 0}, &get_section_line(&1, &2, detailed))
  end

  @spec get_section(result_map :: map()) :: String.t()
  defp get_section(result_map) do
    Enum.reduce(result_map, "", &get_section_line/2)
  end

  @spec get_section_line({
    key :: String.t(), {
        modules :: map(), {
          checked :: integer,
          all :: integer
        }
      }
    }, {
      result :: Strin.t(),
      sum_checked :: integer,
      sum_all :: integer,
    },
    detailed:: boolean
  ) :: {
    result :: String.t(),
    sum_checked :: integer,
    sum_all :: integer
  }
  defp get_section_line({key, {modules, {checked, all}}},
    {result, sum_checked, sum_all}, detailed) do
    proc = get_procentage_representation(checked, all)
    if(detailed) do
      {
        "#{result}\n#{get_line(proc, key, checked, all)}\t#{get_section(modules)}",
        sum_checked + checked, sum_all + all
      }
    else
      {
        "#{result}\n#{get_line(proc, key, checked, all)}",
        sum_checked + checked, sum_all + all
      }
    end
  end

  @spec get_section_line({
    key :: String.t(), {
        modules :: map(), {
          checked :: integer,
          all :: integer
        }
      }
    },
    result :: String.t()
  ) :: String.t()
  defp get_section_line({key, {modules, {checked, all}}}, result) do
      proc = get_procentage_representation(checked, all)
      "#{result}\n#{get_line(proc, key, checked, all)}\t#{get_section(modules)}"
  end

  @spec get_section_line({
    key :: String.t(), {
        checked :: integer,
        all :: integer
      }
    },
    result :: String.t()
  ) :: String.t()
  defp get_section_line({key, {checked, all}}, result) do
      "#{result}\n#{get_line("", key, checked, all)}"
  end

  @spec get_procentage_representation(checked :: integer(), all :: integer()) :: String.t()
  defp get_procentage_representation(_, 0) do
    "#{Float.round(0.00, 2)}%"
  end

  defp get_procentage_representation(checked, all) do
    "#{Float.round(checked / all * 100, 2)}%"
  end

  @spec get_line(
          proc :: String.t(),
          key :: String.t(),
          checked :: integer(),
          all :: integer()
        ) :: String.t()
  defp get_line(proc, key, checked, all) do
    proc = String.pad_leading(proc, 7)
    key = String.pad_trailing(key, 60)
    last_column = String.pad_trailing("#{checked}/#{all}", 10)
    "#{proc}\t #{key}\t #{last_column}"
  end
end
