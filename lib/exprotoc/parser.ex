defmodule Exprotoc.Parser do
  @multiline_comment "/\\*([^*]|\\*+[^*/])*\\*+/"
  @line_comment "//.*\\n"

  def tokenize(file, path) do
    file = find_file file, path
    { :ok, text } = File.read file
    { :ok, reg1 } = Regex.compile @multiline_comment
    { :ok, reg2 } = Regex.compile @line_comment
    text = Regex.replace reg1, text, ""
    text = Regex.replace reg2, text, ""
    { :ok, list_text } = String.to_char_list text
    { :ok, tokens, _ } = :erl_scan.string(list_text, 1,
                                          { :reserved_word_fun ,
                                            &reserved_words/1 })
    {file, tokens}
  end

  def find_file(file, []) do
    if File.exists? file do
      file
    else
      raise "Could not locate #{file} in path"
    end
  end
  def find_file(file, [ dir | proto_path ]) do
    file_path = Path.join dir, file
    if File.exists? file_path do
      file_path
    else
      find_file file, proto_path
    end
  end

  def parse({file, tokens}) do
    case :proto_grammar.parse tokens do
      { :ok, ast } ->
        ast
      error ->
        raise "parse error in #{file}: #{inspect(error)}"
    end
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