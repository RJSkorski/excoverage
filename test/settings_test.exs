defmodule Excoverage.Settings.Test do
  @moduledoc false

  alias Excoverage.Settings

  use ExUnit.Case

  test "Validation empty arguments table should return default values" do
    {:ok, result} = Settings.validate_opts([])

    expected = %Settings{
      help: nil,
      ignore_files: [],
      include_folders: ["lib"],
      mode: [:function],
      reports: [:general_report],
      test_folders: ["test"]
    }

    assert(result == expected)
  end

  test "Validation not empty arguments table should return proper values" do

    arguments = [
      help: true,
      ignore_files: "test test1",
      include_folders: "lib lib1",
      function: true,
      branch: true,
      detailed_report: true,
      general_report: true,
      test_folders: "test test1"
    ]

    {:ok, result} = Settings.validate_opts(arguments)

    expected = %Settings{
      help: true,
      ignore_files: ["test", "test1"],
      include_folders: ["lib", "lib1"],
      mode: [:branch, :function],
      reports: [:general_report, :detailed_report],
      test_folders: ["test", "test1"]
    }

    assert(result == expected)
  end

end
