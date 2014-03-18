defmodule Exprotoc.Parser do
  @multiline_comment "/\\*([^*]|\\*+[^*/])*\\*+/"
  @line_comment "//.*\\n"

  def tokenize(file) do
    { :ok, text } = File.read file
    { :ok, reg1 } = Regex.compile @multiline_comment
    { :ok, reg2 } = Regex.compile @line_comment
    text = Regex.replace reg1, text, ""
    text = Regex.replace reg2, text, ""
    { :ok, list_text } = String.to_char_list text
    { :ok, tokens, _ } = :erl_scan.string(list_text, 1,
                                          { :reserved_word_fun ,
                                            &reserved_words/1 })
    tokens
  end

  def parse(tokens) do
    { :ok, ast } = :proto_grammar.parse tokens
    ast
  end

  defp reserved_words(:package), do: true
  defp reserved_words(:message), do: true
  defp reserved_words(:enum), do: true
  defp reserved_words(:packed), do: true
  defp reserved_words(:default), do: true
  defp reserved_words(true), do: true
  defp reserved_words(false), do: true
  defp reserved_words(:import), do: true
  defp reserved_words(_), do: false
end