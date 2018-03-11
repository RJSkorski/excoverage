defmodule Excoverage.CodeParser.Test do
  @moduledoc false

  use ExUnit.Case
  alias Excoverage.CodeParser

  defmodule Excoverage.CodeParser.StorageInitFileMock do
    def register({key, module_name, file_name}) do
      send(self(), {:function_registered, key, module_name, file_name})
      []
    end

    def get_register_ast(key, register_call_line_no) do
      {:send, [line: register_call_line_no], [
         {:self, [line: register_call_line_no], []},
         {:function_check, key}
        ]
      }
    end
  end

  test "init_file should register guard in the table" do
    defmodule Excoverage.CodeParser.FilePublicGuardMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defguard is_positive(a) when a > 0
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicGuardMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.is_positive/1", "TestModule", "file_name"}
  end

  test "init_file should register macro guard in the table" do
    defmodule Excoverage.CodeParser.FilePublicGuardMacroMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defmacro is_even(number) do
            quote do
              is_integer(unquote(number)) and rem(unquote(number), 2) == 0
            end
          end
          def add2(x, y) when is_even(x) do
            x+y
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicGuardMacroMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.is_even/1", "TestModule", "file_name"}
  end

  test "init_file should register macro (only quote in macro) in the table" do
    defmodule Excoverage.CodeParser.FilePublicMarcoMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defmacro macro_unless(clause, do: expression) do
            quote do
              if(!unquote(clause), do: unquote(expression))
            end
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicMarcoMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.macro_unless/2", "TestModule",
                    "file_name"}
  end

  test "init_file should register macro
        (additional function calls added to macro) in the table" do
    defmodule Excoverage.CodeParser.FilePublicMarcoWithAdditionalCallsMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defmacro macro_unless(clause, do: expression) do
            IO.puts "Before"
            quote do
              if(!unquote(clause), do: unquote(expression))
            end
            IO.puts "After"
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicMarcoWithAdditionalCallsMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.macro_unless/2", "TestModule",
                    "file_name"}
  end

  test "init_file should register operator in the table" do
    defmodule Excoverage.CodeParser.FilePublicOperatorMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          def a ~> b, do: max(a, b)
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicOperatorMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.~>/2", "TestModule", "file_name"}
  end

  test "init_file should register functions (no params, public) in the table" do
    defmodule Excoverage.CodeParser.FilePublicNoParamsMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          def add do
            1+1
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicNoParamsMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.add/0", "TestModule", "file_name"}
  end

  test "init_file should register functions (with params, public) in the table" do
    defmodule Excoverage.CodeParser.FilePublicWithParamsMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          def add(x, y) do
            x+y
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePublicWithParamsMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.add/2", "TestModule", "file_name"}
  end

  test "init_file should register functions (with params, private) in the table" do
    defmodule Excoverage.CodeParser.FilePrivateWithParamsMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defp add(x, y) do
            x+y
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePrivateWithParamsMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.add/2", "TestModule", "file_name"}
  end

  test "init_file should register functions (no params, private) in the table" do
    defmodule Excoverage.CodeParser.FilePrivateWithoutParamsMock do
      def read_file(_filename) do
        source = """
        defmodule TestModule do
          defp add() do
            1+3
          end
        end
        """

        {:ok, source}
      end
    end

    CodeParser.init_files(
      ["file_name"],
      Excoverage.CodeParser.FilePrivateWithoutParamsMock,
      Excoverage.CodeParser.StorageInitFileMock
    )

    assert_receive {:function_registered, "2:TestModule.add/0", "TestModule", "file_name"}
  end

  test "get_results should return empty map when is nothing in the table" do
    defmodule Excoverage.CodeParser.StorageEmptyMock do
      def get_table_content() do
        []
      end
    end

    expected = %{}

    assert CodeParser.get_results(Excoverage.CodeParser.StorageEmptyMock) == expected
  end

  test "get_results should return results in rigth format" do
    defmodule Excoverage.CodeParser.StorageMock do
      def get_table_content() do
        [{{"fun", "module", "file"}, 1}, {{"fun2", "module", "file"}, 0}]
      end
    end

    expected = %{
      "file" => {%{"module" => {%{"fun" => {1, 1}, "fun2" => {0, 1}}, {1, 2}}}, {1, 2}}
    }

    assert CodeParser.get_results(Excoverage.CodeParser.StorageMock) == expected
  end
end
