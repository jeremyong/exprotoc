defmodule Exprotoc.AST do
  @moduledoc "Generates a structured AST from the AST produced by the parser."

  def generate_ast({package, imports, {enums, messages}}) do
    ast = generate_symbols enums, messages, HashDict.new
    {package, ast}
  end

  def search_ast(ast, [], needle) do
    module = traverse_ast ast, needle
    if module == nil do
      name = Exprotoc.Generator.get_module_name needle
      raise "Could not identify symbol for #{name}."
    else
      { module, needle }
    end
  end
  def search_ast(ast, inner = [_|outer], needle) do
    reversed_scope = Enum.reverse inner
    branch = traverse_ast ast, reversed_scope
    module = traverse_ast branch, needle
    if module == nil do
      search_ast ast, outer, needle
    else
      { module, reversed_scope ++ needle }
    end
  end

  def traverse_ast(_, []), do: nil
  def traverse_ast({ _, ast }, [pointer]) do
    if HashDict.has_key?(ast, pointer) do
      ast[pointer]
    else
      nil
    end
  end
  def traverse_ast({ _, ast }, [pointer|pointers]) do
    if HashDict.has_key?(ast, pointer) do
      traverse_ast ast[pointer], pointers
    else
      nil
    end
  end

  defp generate_symbols(enums, messages, symbol_tree) do
    symbol_tree = List.foldl enums, symbol_tree, &add_enum/2
    List.foldl messages, symbol_tree, &add_message/2
  end

  defp add_enum({ :enum, enum, enum_data }, symbol_tree) do
    if nil? symbol_tree[enum] do
      symbol_tree = HashDict.put symbol_tree, enum, { :enum, enum_data }
    else
      raise "Duplicate symbol for enum #{enum}."
    end
    symbol_tree
  end

  defp add_message({ :message, message, { enums, messages, fields } },
                   symbol_tree) do
    if nil? symbol_tree[message] do
      subtree = HashDict.new
      subtree = generate_symbols(enums, messages, subtree)
      symbol_tree = HashDict.put symbol_tree, message, {fields, subtree}
    else
      raise "Duplicate symbol for message #{message}."
    end
    symbol_tree
  end
end