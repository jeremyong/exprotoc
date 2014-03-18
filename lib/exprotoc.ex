defmodule Exprotoc do
  import Exprotoc.Parser
  import Exprotoc.AST
  def compile(file, dir) do
    ast = file |> tokenize |> parse |> generate_ast
    Exprotoc.Generator.generate_code ast, dir
  end
end
