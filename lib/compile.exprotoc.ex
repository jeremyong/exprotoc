defmodule Mix.Tasks.Compile.Exprotoc do
  use Mix.Task

  def run(_) do
    { :ok, out_dir } = get_out_dir
    File.mkdir_p out_dir
    { :ok, proto_files } = Keyword.fetch Mix.project, :proto_files
    { :ok, proto_path } = get_path
    Enum.each proto_files, &Exprotoc.compile(&1, out_dir, proto_path)
  end

  defp get_out_dir do
    path = Keyword.fetch Mix.project, :proto_out
    if path == :error do
      { :ok, cwd } = File.cwd
      path = Path.join cwd, "lib"
      { :ok, path }
    else
      path
    end
  end

  defp get_path do
    path = Keyword.fetch Mix.project, :proto_path
    if path == :error do
      { :ok, [] }
    else
      path
    end
  end
end