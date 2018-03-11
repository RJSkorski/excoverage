defmodule Excoverage.CodeParser do
  @moduledoc """
  This module contains a set of function for registering modules and retriving results of test coverage from the storage
  """

  @type function_module_name_tuple :: {
    String.t(),
    String.t()
  }

  @type ast_with_module_file_name_tuple :: {
    Macro.t(),
    {
      String.t(),
      String.t()
    }
  }

  @spec traverse_file(code :: Macro.t(), file_name :: String.t(), storage :: module()) ::
          ast_with_module_file_name_tuple
  defp traverse_file(code, file_name, storage) do
    Macro.prewalk(code, {"", file_name}, &traverse_line(&1, &2, storage))
  end

  @spec create_function_ast(
    storage :: module(),
    def_line_no :: integer(),
    module_name :: String.t(),
    function_name :: atom(),
    params :: list(),
    file_name :: String.t(),
    funtion_type :: atom(),
    function_content :: list(),
    function_name_line_no :: integer()
  ) :: ast_with_module_file_name_tuple
  defp create_function_ast(
     storage,
     def_line_no,
     module_name,
     function_name,
     params,
     file_name,
     funtion_type,
     function_content,
     function_name_line_no
   ) do
    {real_function_name, real_params} = get_real_function_details(function_name, params)

    entry = create_entry(def_line_no, module_name, real_function_name, real_params, file_name)
    {key, _, _} = entry

    storage.register(entry)

    register_call_line_no = function_name_line_no + 1

    function_content = get_content(register_call_line_no, key, function_content, storage)

    ast = {funtion_type, [line: def_line_no],
      [
        {function_name, [line: function_name_line_no], params},
        [do: {:__block__, [], function_content}]
      ]
    }

    {ast, {module_name, file_name}}
  end

  @spec get_real_function_details(
    function_name :: atom(),
    params :: list()) ::
      {atom(), list()}
  defp get_real_function_details(:when, params) do
    [{real_function_name, real_params, _} | _] = params

    {real_function_name, real_params}
  end

  defp get_real_function_details(function_name, params) do
    {function_name, params}
  end

  @spec get_content(
    register_call_line_no :: number(),
    key :: String.t(),
    content :: list(),
    storage :: module())
      :: list()
  defp get_content(register_call_line_no, key, content, storage) when is_list(content) do
    register_ast = storage.get_register_ast(key, register_call_line_no)
    [register_ast | content]
  end

  @spec get_content(
    register_call_line_no :: number(),
    key :: String.t(),
    content :: tuple(),
    storage :: module())
      :: list()
  defp get_content(register_call_line_no, key, content, storage) do
    register_ast = storage.get_register_ast(key, register_call_line_no)
    [register_ast, content]
  end

  @spec traverse_line(ast :: Macro.t(), key :: function_module_name_tuple, storage :: module()) ::
          ast_with_module_file_name_tuple
  defp traverse_line(ast =
    {
      :defmodule, [line: _line_no],
        [
          {:__aliases__, _line_count, new_module_name}, [do: _content]
        ]
    },
    {_module_name, file_name}, _storage
  ) do

    {ast, {Enum.join(new_module_name, "."), file_name}}

  end

  @spec traverse_line(ast :: Macro.t(), key :: function_module_name_tuple, storage :: module()) ::
          ast_with_module_file_name_tuple
  defp traverse_line(
    {
    function_type, [line: def_line_no],
      [
        {function_name, [line: function_name_line_no], params},
        [do: {:__block__, [], function_content}]
      ]
    },
    {module_name, file_name},
    storage
  ) when function_type in [:def, :defp, :defmacro, :defmacrop] do

    create_function_ast(
      storage,
      def_line_no,
      module_name,
      function_name,
      params,
      file_name,
      function_type,
      function_content,
      function_name_line_no
    )
  end

  @spec traverse_line(ast :: Macro.t(), key :: function_module_name_tuple, storage :: module()) ::
          ast_with_module_file_name_tuple
  defp traverse_line(
    {
      function_type, [line: def_line_no],
      [
        {function_name, [line: function_name_line_no], params},
        [do: function_content]
      ]
    },
    {module_name, file_name},
    storage
  )
    when function_type in [:def, :defp, :defmacro, :defmacrop] do

      create_function_ast(
        storage,
        def_line_no,
        module_name,
        function_name,
        params,
        file_name,
        function_type,
        function_content,
        function_name_line_no
      )
  end

  @spec traverse_line(
        ast :: Macro.t(),
        key :: function_module_name_tuple,
        storage :: module()
      ) :: ast_with_module_file_name_tuple
  defp traverse_line(
    {guard_type, [line: def_line_no],
     [
       {:when, [line: when_line_no],
        [
          {guard_name, [line: _guard_name_no], params},
          content
        ]}
     ]},
   {module_name, file_name},
   storage
 ) when guard_type in [:defguard, :defguardp] do
   content = replace_params(content, params)

   macro_type = get_macro_type_for_guard(guard_type)

   create_function_ast(
      storage,
      def_line_no,
      module_name,
      guard_name,
      params,
      file_name,
      macro_type,
      {:quote, [line: when_line_no + 1], [[do: content]]},
      when_line_no
    )
  end

  @spec traverse_line(
          ast :: Macro.t(),
          key :: function_module_name_tuple,
          storage :: module()
        ) :: ast_with_module_file_name_tuple
  defp traverse_line(ast, {module_name, file_name}, _storage) do
    {ast, {module_name, file_name}}
  end

  @spec replace_params(content :: Macro.t(), params :: list()) :: Macro.t()
  def replace_params(content, params) do
    Enum.reduce(params, content,
      fn({param_name, [line: param_line_no], nil}, cont) ->
        Macro.postwalk(cont, fn(ast) ->
            case ast do
              {^param_name, [line: ^param_line_no], nil} ->
                {:unquote, [line: param_line_no + 1], [{param_name, [line: param_line_no + 1], nil}]}
              _ ->
                ast
            end
          end
        )
      end
    )
  end

  def get_macro_type_for_guard(guard_type) do
    case guard_type do
      :defguardp -> :defmacrop
      _ -> :defmacro
    end
  end

  @spec count_params(params :: list() | nil) :: integer()
  defp count_params(params) when is_nil(params) do
    0
  end

  defp count_params(params) do
    Enum.count(params)
  end

  @spec create_entry(
          def_line_no :: integer,
          module_name :: String.t(),
          function_name :: atom(),
          params :: list(),
          file_name :: String.t()
        ) :: {String.t(), String.t(), String.t()}
  defp create_entry(def_line_no, module_name, function_name, params, file_name) do
    {
      "#{def_line_no}:#{module_name}.#{function_name}/#{count_params(params)}",
      module_name,
      file_name
    }
  end

  @doc """
  Initialize files to be checked
  """
  @spec init_files(file_names :: list(), files :: module(), storage :: module()) :: :ok
  def init_files(file_names, files, storage) do
    Code.compiler_options(ignore_module_conflict: true)
    Enum.map(file_names, &init_file(files, storage, &1))
    Code.compiler_options(ignore_module_conflict: false)
    :ok
  end

  @spec init_file(files :: module(), storage :: module(), file_name :: String.t()) :: :ok
  defp init_file(files, storage, file_name) do
    {:ok, source} = files.read_file(file_name)

    Code.string_to_quoted(source)
    |> traverse_file(file_name, storage)
    |> Code.compile_quoted(file_name)

    :ok
  end

  @doc """
  Retrives coverage results
  """
  @spec get_results(storage :: module()) :: map()
  def get_results(storage) do
    storage.get_table_content
    |> generate_results(2)
  end

  @spec generate_results(content :: list(), positon :: integer) :: map()
  defp generate_results(content, position) do
    Enum.group_by(content, fn {tuple, _} -> elem(tuple, position) end)
    |> calculate_coverage(position)
  end

  defp calculate_coverage(function_map, position) when position == 0 do
    for {key, [{_, val}]} <- function_map, into: %{}, do: {key, {val, 1}}
  end

  @spec calculate_coverage(function_map :: map(), position :: integer) :: map()
  defp calculate_coverage(function_map, position) do
    for {key, val} <- function_map,
        into: %{},
        do: {
            key,{
              generate_results(val, position - 1),
              Enum.reduce(val, {0, 0}, fn {_, checked}, {no_of_checked, all} ->
                {no_of_checked + checked, all + 1}
              end)
            }
          }
  end
end
