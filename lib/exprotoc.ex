defmodule Exprotoc do
  import Exprotoc.Parser
  import Exprotoc.AST
  def compile(file, out_dir, proto_path) do
    ast = file |> tokenize(proto_path) |> parse |> generate_ast(proto_path)
    Exprotoc.Generator.generate_code ast, out_dir
  end
end
