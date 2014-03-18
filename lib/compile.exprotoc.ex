defmodule Mix.Tasks.Compile.Exprotoc do
  use Mix.Task

  def run(_) do
    { :ok, cwd } = File.cwd
    target = Path.join cwd, "lib"
    File.mkdir_p target
    { :ok, proto_files } = Keyword.fetch Mix.project, :proto_files
    Enum.map proto_files, &Exprotoc.compile(&1, target)
  end
end