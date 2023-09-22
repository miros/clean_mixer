defmodule CleanMixer.CodeMap.Typespec do
  alias CleanMixer.CodeMap.CodeModule

  @spec referenced_modules(tuple) :: [CodeModule.name()]
  def referenced_modules({_, children}) do
    Enum.flat_map(children, &remote_type_refs/1)
  end

  defp remote_type_refs({_, _, _, [{:remote_type, _, [{:atom, _, module_name} | other_sub_children]} | other_children]}) do
    [module_name] ++
      Enum.flat_map(other_sub_children, &remote_type_refs/1) ++ Enum.flat_map(other_children, &remote_type_refs/1)
  end

  defp remote_type_refs({_, _, _, [_ | other_children]}) do
    Enum.flat_map(other_children, &remote_type_refs/1)
  end

  defp remote_type_refs(_) do
    []
  end
end
