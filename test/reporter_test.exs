defmodule Excoverage.Reporter.Test do
  @moduledoc false

  use ExUnit.Case
  alias Excoverage.Reporter

  test "reporter should generate empty report for empty result map" do
    result = Reporter.generate_txt_report(%{}, [:general_report])

    assert result == {:ok, "No files to be examinated"}
  end

  test "reporter should generate a accurate standard report for empty module" do
    report_map = %{
      "lib/cli.ex" =>
        {%{
           "Excoverage.CLI" => {%{}, {0, 0}}
         }, {0, 0}}
    }

    regex = ~r/0\.0%\t lib\/cli.ex\s+\t\s0\/0\s+\n\s+0\.0%\t Overall\s+0\/0/

    {:ok, result} = Reporter.generate_txt_report(report_map, [:general_report])

    assert Regex.match?(regex, result)
  end

  test "reporter should generate a accurate detailed report for empty module" do
    report_map = %{
      "lib/cli.ex" =>
        {%{
           "Excoverage.CLI" => {%{}, {0, 0}}
         }, {0, 0}}
    }

    regex = ~r/0\.0%\t lib\/cli.ex\s+\t\s0\/0\s+\n\s+0\.0%\t Excoverage.CLI\s+\t\s0\/0\s+\n\s+0\.0%\t Overall\s+0\/0/

    {:ok, result} = Reporter.generate_txt_report(report_map, [:detailed_report])
    assert Regex.match?(regex, result)
  end

  test "reporter should generate a accurate general report for module with some functions" do
    report_map = %{
      "lib/cli.ex" =>
        {%{
           "Excoverage.CLI" =>
             {%{
                "20:Excoverage.CLI.main/1" => {1, 1},
                "27:Excoverage.CLI.process/1" => {0, 1},
                "31:Excoverage.CLI.parse_args/1" => {0, 1}
              }, {1, 3}}
         }, {1, 3}}
    }

    regex = ~r/33\.33%\t lib\/cli.ex\s+\t\s1\/3\s+\n\s+33\.33%\t Overall\s+1\/3/

    {:ok, result} = Reporter.generate_txt_report(report_map, [:general_report])

    assert Regex.match?(regex, result)
  end
end
