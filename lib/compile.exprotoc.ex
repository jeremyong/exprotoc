defmodule Mix.Tasks.Compile.Exprotoc do
  use Mix.Task

  def run(_) do
    { :ok, out_dir } = get_out_dir
    File.mkdir_p out_dir
    { :ok, proto_files } = Keyword.fetch Mix.project, :proto_files
    { :ok, proto_path } = get_path
    { :ok, proto_namespace } = get_namespace
    Enum.each proto_files, &Exprotoc.compile(&1, out_dir, proto_path, proto_namespace)
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

  defp get_namespace do
    namespace = Keyword.fetch Mix.project, :proto_namespace
    if namespace == :error do
      { :ok, app_name } = Keyword.fetch Mix.project, :app
      { :ok, to_namespace(app_name) }
    else
      namespace
    end
  end

  defp to_namespace(name) do
    name
      |> atom_to_binary
      |> String.split(~r{_+})
      |> Enum.map( &(String.capitalize(&1)) )
      |> Enum.join
  end
end