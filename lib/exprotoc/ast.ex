defmodule Exprotoc.AST do
  import Exprotoc.Parser

  @moduledoc "Generates a structured AST from the AST produced by the parser."

  def generate_ast({ :no_package, imports, { enums, messages } }, proto_path) do
    ast = generate_symbols enums, messages, HashDict.new
    full_ast = generate_import_ast imports, proto_path, ast
    { ast, full_ast }
  end
  def generate_ast({ { :package, package }, imports, { enums, messages } },
                   proto_path) do
    ast = generate_symbols enums, messages, HashDict.new
    ast = HashDict.put HashDict.new, package, { [], ast }
    full_ast = generate_import_ast imports, proto_path, ast
    { package, ast, full_ast }
  end

  defp generate_import_ast([], _, acc), do: acc
  defp generate_import_ast([ i | imports ], proto_path, acc) do
    file = find_file i, proto_path
    { package, _, { enums, messages } } = file |> tokenize(proto_path) |> parse
    ast = generate_symbols enums, messages, HashDict.new
    acc = merge_asts { package, ast }, acc
    generate_import_ast imports, proto_path, acc
  end

  defp merge_asts({ :nopackage, modules }, ast) do
    HashDict.merge modules, ast, fn(k, _, _) ->
                                     raise "Ambiguous name for #{k}."
                                 end
  end
  defp merge_asts({ { :package, package }, modules }, ast) do
    if HashDict.has_key? ast, package do
      raise "Ambiguous name for #{package}."
    end
    HashDict.put ast, package, { [], modules }
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