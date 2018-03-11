defmodule Excoverage.Files do
  @moduledoc """
  Helper module fot handling an access to source code files.
  """

  @doc """
  Gets a list of elixir file names
  """
  @spec get_file_names(paths :: [], ignore_files :: [String.t()]) :: list()
  def get_file_names([], ignore_files) do
    get_file_names(["lib"], ignore_files)
  end

  @spec get_file_names(paths :: [String.t()], ignore_files :: [String.t()]) :: list()
  def get_file_names(folders, ignore_files) do
    Enum.reduce(folders, [], fn(folder, files) ->
      files ++ Path.wildcard("#{folder}/*.ex")
    end)
    |> (&Enum.reduce(ignore_files, &1, fn(ignore_file, files) ->
      List.delete(files, ignore_file)
    end)).()
  end


  @doc """
  Reads file content
  """
  @spec read_file(file_name :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def read_file(file_name) do
    {:ok, pid} = File.open(file_name)
    read_file("", pid)
  end

  @spec read_file(source :: String.t(), pid :: pid()) :: {:ok, String.t()} | {:error, String.t()}
  defp read_file(source, pid) do
    case IO.read(pid, :line) do
      {:error, reason} ->
        {:error, reason}

      :eof ->
        {:ok, source}

      data ->
        source = source <> data
        read_file(source, pid)
    end
  end
end
