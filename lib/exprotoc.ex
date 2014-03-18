defmodule Exprotoc do
  import Exprotoc.Parser
  import Exprotoc.AST
  def compile(file, dir, proto_path) do
    ast = file |> tokenize |> parse |> generate_ast(proto_path)
    Exprotoc.Generator.generate_code ast, dir
  end
end
