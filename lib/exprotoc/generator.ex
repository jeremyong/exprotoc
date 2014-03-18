defmodule Exprotoc.Generator do
  @moduledoc "Given a structured AST, generate code files into an output dir."

  def generate_code({ ast, full_ast }, dir) do
    File.mkdir_p dir
    generate_modules { [], full_ast }, [], HashDict.to_list(ast), dir
  end
  def generate_code({ package, ast, full_ast}, dir) do
    dir = create_package_dir package, dir
    { [], ast } = ast[package]
    generate_modules { [], full_ast }, [package], HashDict.to_list(ast), dir
  end

  defp create_package_dir(package, dir) do
    package_name = to_enum_type package
    dir = dir |> Path.join(package_name)
    File.mkdir_p dir
    dir
  end

  defp generate_modules(_, _, [], _) do end
  defp generate_modules(ast, scope, [module|modules], dir) do
    { name, _ } = module
    new_scope = [ name | scope ]
    module_filename = name |> atom_to_binary |> to_module_filename
    path = Path.join dir, module_filename
    IO.puts "Generating #{module_filename}"
    module_text = generate_module ast, new_scope, module, 0, false
    File.write path, module_text
    generate_modules ast, scope, modules, dir
  end

  defp generate_module(_, scope, { _, { :enum, enum_values } }, level, sub) do
    fullname = scope |> Enum.reverse |> get_module_name
    if sub do
      [name|_] = scope
      name = atom_to_binary name
    else
      name = fullname
    end
    i = indent level
    enum_funs = List.foldl enum_values, "",
                     fn({k, v}, acc) ->
                         enum_atom = to_enum_type k
                         """
#{i}  def to_i({ #{fullname}, :#{enum_atom} }), do: #{v}
#{i}  def to_symbol(#{v}), do: { #{fullname}, :#{enum_atom} }
#{i}  def #{enum_atom}, do: { #{fullname}, :#{enum_atom} }
""" <> acc
                     end
    """
#{i}defmodule #{name} do
#{i}  def decode(value), do: to_symbol value
#{enum_funs}#{i}end
"""
  end
  defp generate_module(ast, scope, module, level, sub) do
    if sub do
      [name|_] = scope
      name = atom_to_binary name
    else
      name = scope |> Enum.reverse |> get_module_name
    end
    i = indent level
    fields_text = process_fields ast, scope, module, level
    submodules = module |> elem(1) |> elem(1) |> HashDict.to_list
    submodule_text = List.foldl submodules, "",
                          fn(m = { n, _ }, acc) ->
                              acc <> generate_module(ast, [n|scope],
                                                     m, level + 1, true)
                          end

    """
#{i}defmodule #{name} do
#{i}  defrecord T, message: HashDict.new
#{i}  def encode(msg) do
#{i}    p = Enum.map msg.message, fn({ k, v }) ->
#{i}          { k, { get_type(k), v } }
#{i}        end
#{i}    Exprotoc.Protocol.encode_message p
#{i}  end

#{i}  def decode(payload) do
#{i}    m = Exprotoc.Protocol.decode_payload payload, __MODULE__
#{i}    T.new message: m
#{i}  end

#{i}  def new, do: T.new
#{i}  def new(enum) do
#{i}    m = T.new
#{i}    m = Enum.reduce enum, m, fn({k, v}, acc) ->
#{i}          put acc, k, v
#{i}        end
#{i}    m
#{i}  end
#{i}  def get(msg, key) do
#{i}    f_num = get_fnum key
#{i}    m = msg.message
#{i}    if get_ftype(f_num) == :repeated do
#{i}      elem m[f_num], 1
#{i}    else
#{i}      m[f_num]
#{i}    end
#{i}  end
#{i}  def put(msg, key, value) do
#{i}    f_num = get_fnum key
#{i}    m = msg.message
#{i}    m = put_key m, f_num, value
#{i}    msg.message m
#{i}  end
#{i}  def delete(msg, key) do
#{i}    f_num = get_fnum key
#{i}    m = msg.message
#{i}    m = HashDict.delete m, f_num
#{i}    msg.message m
#{i}  end
#{i}
#{fields_text}#{submodule_text}#{i}end
#{i}
#{i}defimpl Access, for: #{name}.T do
#{i}  def access(msg, key), do: #{name}.get(msg, key)
#{i}end
"""
  end

  def get_module_name(names) do
    Enum.join names, "."
  end

  defp process_fields(ast, scope, { _, { fields, _ } }, level) do
    process_fields ast, scope, fields, level
  end
  defp process_fields(ast, scope, fields, level) do
    acc = { "", "", "", "" }
    { acc1, acc2, acc3, acc4 } =
      List.foldl fields, acc,
           &process_field(ast, scope, &1, &2, level)
    acc1 <> acc2 <> acc3 <> acc4
  end

  defp process_field(ast, scope, { :field, ftype, type, name, fnum, opts },
                     { acc1, acc2, acc3, acc4 } , level) do
    i = indent level + 1
    type = type_to_string ast, scope, type
    if ftype == :repeated do
      acc1 = acc1 <> """
#{i}defp put_key(msg, #{fnum}, values) when is_list(values) do
#{i}  HashDict.put msg, #{fnum}, { :repeated, values }
#{i}end
"""
    else
      acc1 = acc1 <> """
#{i}defp put_key(msg, #{fnum}, value) do
#{i}  HashDict.put msg, #{fnum}, value
#{i}end
"""
    end
    acc2 = acc2 <> "#{i}def get_fnum(:#{name}), do: #{fnum}\n"
    acc3 = acc3 <> "#{i}def get_ftype(#{fnum}), do: :#{ftype}\n"
    acc4 = acc4 <> "#{i}def get_type(#{fnum}), do: #{type}\n"
    { acc1, acc2, acc3, acc4 }
  end

  defp indent(level), do: String.duplicate("  ", level)

  defp type_to_string(ast, scope, type) when is_list(type) do
    { module, pointer } = Exprotoc.AST.search_ast ast, scope, type
    if elem(module, 0) == :enum do
      "{ :enum, " <> get_module_name(pointer) <> " }"
    else
      "{ :message, " <> get_module_name(pointer) <> " }"
    end
  end
  defp type_to_string(ast, scope, type) do
    if Exprotoc.Protocol.wire_type(type) == :custom do
      type_to_string ast, scope, [type]
    else
      ":" <> atom_to_binary(type)
    end
  end

  defp to_module_filename(module) do
    module = String.downcase module
    Regex.replace(~r/\./, module, "_") <> ".ex"
  end

  defp to_enum_type(name) do
    name = atom_to_binary name
    name = Regex.replace ~r/([A-Z])/, name, "_\\1"
    name |> String.lstrip(?_) |> String.downcase
  end
end