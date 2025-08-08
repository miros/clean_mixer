defmodule CleanMixer.CompilerManifests.Manifest do
  alias CleanMixer.CodeMap.CodeModule
  alias CleanMixer.CodeMap.SourceFile
  alias CleanMixer.CodeMap.ModuleReference

  require Mix.Compilers.Elixir, as: Compiler

  @spec parse({modules :: list(term), sources :: list(term)}) :: list(SourceFile.t())
  def parse({module_items, source_items}) do
    modules = module_items |> Enum.map(&parse_module_record/1) |> Enum.reject(&is_nil/1)
    manifest_files(source_items, modules)
  end

  defp parse_module_record({name, Compiler.module(sources: [path | _])}) do
    CodeModule.new(name, path)
  end

  defp parse_module_record(module_record)
       when is_tuple(module_record) and
              tuple_size(module_record) >= 6 and
              elem(module_record, 0) == :module do
    name = elem(module_record, 1)
    [path | _] = elem(module_record, 3)
    CodeModule.new(name, path)
  end

  defp parse_module_record(_module_record) do
    nil
  end

  defp manifest_files(items, all_manifest_modules) do
    Enum.map(items, &source_file_for(&1, all_manifest_modules))
  end

  defp source_file_for(source_item, all_manifest_modules) do
    source_params =
      case source_item do
        {source, source_item} ->
          source_item |> Compiler.source() |> Keyword.put(:source, source)

        source_item ->
          Compiler.source(source_item)
      end

    references =
      references_of(:compile, source_params[:compile_references]) ++
        references_of(:runtime, source_params[:runtime_references]) ++
        references_of(:struct, source_params[:struct_references]) ++
        references_of(:export, source_params[:export_references])

    module_names = modules_for_path(source_params[:source], all_manifest_modules) |> Enum.map(& &1.name)

    %SourceFile{
      path: source_params[:source],
      modules: module_names,
      references: references ++ Enum.flat_map(module_names, &CodeModule.typespec_references/1)
    }
  end

  defp modules_for_path(path, modules) do
    Enum.filter(modules, &(&1.path == path))
  end

  defp references_of(_type, _module_names = nil) do
    []
  end

  defp references_of(type, module_names) do
    module_names |> Enum.map(&ref_for(&1, type))
  end

  defp ref_for(module_name, type) do
    %ModuleReference{module_name: module_name, ref_type: type}
  end
end
